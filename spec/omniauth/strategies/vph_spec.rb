require 'spec_helper'

describe OmniAuth::Strategies::Vph do

  class VphProvider < OmniAuth::Strategies::Vph; end

  let(:app) do
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use VphProvider, name: 'vph', title: 'MI Form', host: 'http://mi.host'
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  let(:session) do
    last_request.env['rack.session']
  end

  describe '/auth/vph' do
    before(:each){ get '/auth/vph' }

    it 'displays a form' do
      last_response.status.should == 200
      last_response.body.should be_include("<form")
    end

    it 'has the callback as the action for the form' do
      last_response.body.should be_include("action='/auth/vph/callback'")
    end

     it 'should have a text field' do
      last_response.body.scan('<input').size.should == 1
    end
    it 'has a label of the form title' do
      last_response.body.scan('MI Form').size.should > 1
    end
  end

  describe 'post /auth/vph/callback' do
    before(:each) do
      @adaptor = double(OmniAuth::Vph::Adaptor)
      OmniAuth::Vph::Adaptor.stub(:new).and_return(@adaptor)
    end

    context 'success' do
      let(:auth_hash){ last_request.env['omniauth.auth'] }
      before(:each) do
        info = {
          "username" => "foobar",
          "language" => "",
          "country"=> "POLAND",
          "role" => [ "Developer", "admin", "cloudadmin", "vph" ],
          "postcode" => "30950",
          "fullname" => "Foo Bar",
          "email" => "foobar@gmail.pl"
        }

        allow(@adaptor).to receive(:user_info).with('ticket_payload').and_return(info)

        allow(@adaptor).to receive(:map_user).with(info).and_return({
            'email' => info['email'],
            'login' => info['username'],
            'full_name' => info['fullname'],
            'roles' => ['admin', 'developer']
          })

        post('/auth/vph/callback', {ticket: 'ticket_payload'})
      end

      it 'should not redirect to error page' do
        last_response.should_not be_redirect
      end

      it 'should map user info to Auth Hash' do
        expect(auth_hash.uid).to eq 'foobar'
        expect(auth_hash.info.email).to eq 'foobar@gmail.pl'
        expect(auth_hash.info.login).to eq 'foobar'
        expect(auth_hash.info.full_name).to eq 'Foo Bar'
        expect(auth_hash.info.roles).to eq ['admin', 'developer']
      end
    end

    context 'failure' do
      before(:each) do
        allow(@adaptor).to receive(:user_info).and_return(false)
      end

      context 'when ticket is not present' do
        it 'redirects to error page' do
          post('/auth/vph/callback', {})

          last_response.should be_redirect
          last_response.headers['Location'].should =~ %r{missing_credentials}
        end
      end

      context "when ticket is empty" do
        it 'redirects to error page' do
          post('/auth/vph/callback', {ticket: ""})

          last_response.should be_redirect
          last_response.headers['Location'].should =~ %r{missing_credentials}
        end
      end

      context "when username and password are present" do
        context "and bind on master interface server failed" do
          it 'redirects to error page' do
            post('/auth/vph/callback', {ticket: 'ticket_payload'})

            last_response.should be_redirect
            last_response.headers['Location'].should =~ %r{invalid_credentials}
          end
        end
      end
    end
  end
end