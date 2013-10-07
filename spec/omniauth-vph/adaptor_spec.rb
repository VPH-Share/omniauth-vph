require 'spec_helper'

describe OmniAuth::Vph::Adaptor do
  let(:adaptor) { OmniAuth::Vph::Adaptor.new({host: 'http://validatetkt.host', roles_map: { 'cloudadmin' => 'admin', 'Developer' => 'developer' }}) }

  describe '#initialize' do
    it 'should throw exception when must have field is not set' do
      expect {
        #[:host]
        OmniAuth::Vph::Adaptor.new({})
      }.to raise_error(ArgumentError)
    end
  end

  describe '#user_info' do
    before(:each) do
      @faraday = double(Faraday)
      Faraday.stub(:new).and_return(@faraday)

      allow(@faraday).to receive(:get).with('/validatetkt/', {ticket: 'correct_ticket'}).and_return(faraday_response(200, '{"user": "details"}'))

      allow(@faraday).to receive(:get).with('/validatetkt/', {ticket: 'wrong_ticket'}).and_return(faraday_response 403)

      allow(@faraday).to receive(:get).with('/validatetkt/', {ticket: 'wrong_host'}).and_raise(Exception.new)

      adaptor = OmniAuth::Vph::Adaptor.new({host: 'http://validatetkt.host'})
    end

    it 'returns nil when user ticket is not valid' do
      expect(adaptor.user_info('wrong_ticket')).to be_nil
    end

    it 'returns user infor when ticket is valid' do
      expect(adaptor.user_info('correct_ticket')).to eq({"user" => "details"})
    end

    it 'throws ConnectionError when unable to connect to the service' do
      expect {
        adaptor.user_info('wrong_host')
      }.to raise_error(OmniAuth::Vph::Adaptor::ConnectionError)
    end
  end

  describe '#map_user' do
    let(:info) do
      {
        "username" => "foobar",
        "language" => "",
        "country"=> "POLAND",
        "role" => [ "Developer", "admin", "cloudadmin", "vph" ],
        "postcode" => "30950",
        "fullname" => "Foo Bar",
        "email" => "foobar@gmail.pl"
      }
    end

    it 'returns user info' do
      user_map = adaptor.map_user info

      expect(user_map['email']).to eq 'foobar@gmail.pl'
      expect(user_map['login']).to eq 'foobar'
      expect(user_map['full_name']).to eq 'Foo Bar'
      expect(user_map['roles']).to eq ['admin', 'developer']
    end
  end

  def faraday_response(status, body=nil)
    response = double Faraday::Response
    allow(response).to receive(:status).and_return status
    allow(response).to receive(:body).and_return body
    response
  end
end