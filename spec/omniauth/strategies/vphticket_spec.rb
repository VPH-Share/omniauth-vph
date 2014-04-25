require 'spec_helper'

describe OmniAuth::Strategies::Vphticket do

  class VphticketProvider < OmniAuth::Strategies::Vphticket; end

  let(:app) do
    Rack::Builder.new do
      use OmniAuth::Test::PhonySession
      use VphticketProvider,
          name: 'vph',
          title: 'MI Form',
          host: 'http://mi.host'

      run lambda { |env|
            [404, { 'Content-Type' => 'text/plain' },
             [env.key?('omniauth.auth').to_s]]
          }
    end.to_app
  end

  let(:session) do
    last_request.env['rack.session']
  end

  describe '/auth/vph' do
    before(:each) { get '/auth/vph' }

    it 'displays a form' do
      expect(last_response.status).to eq 200
      expect(last_response.body).to include('<form')
    end

    it 'has the callback as the action for the form' do
      expect(last_response.body).to include("action='/auth/vph/callback'")
    end

    it 'has a text field' do
      expect(last_response.body.scan('<input').size).to eq 1
    end

    it 'has a label of the form title' do
      expect(last_response.body.scan('MI Form').size).to be > 1
    end
  end

  describe 'post /auth/vph/callback' do
    before(:each) do
      @adaptor = double(OmniAuth::Vph::Adaptor)
      OmniAuth::Vph::Adaptor.stub(:new).and_return(@adaptor)
    end

    context 'success' do
      let(:auth_hash) { last_request.env['omniauth.auth'] }
      before(:each) do
        info = {
          'username' => 'foobar',
          'language' => '',
          'country' => 'POLAND',
          'role' => %w(Developer admin cloudadmin vph),
          'postcode' => '30950',
          'fullname' => 'Foo Bar',
          'email' => 'foobar@gmail.pl'
        }

        allow(@adaptor).to receive(:user_info)
          .with('ticket_payload').and_return(info)

        allow(@adaptor).to receive(:map_user).with(info).and_return(
            'email' => info['email'],
            'login' => info['username'],
            'full_name' => info['fullname'],
            'roles' => %w(admin developer)
          )

        post('/auth/vph/callback', ticket: 'ticket_payload')
      end

      it 'does not redirect to error page' do
        expect(last_response).not_to be_redirect
      end

      it 'maps user info to Auth Hash' do
        expect(auth_hash.uid).to eq 'foobar'
        expect(auth_hash.info.email).to eq 'foobar@gmail.pl'
        expect(auth_hash.info.login).to eq 'foobar'
        expect(auth_hash.info.full_name).to eq 'Foo Bar'
        expect(auth_hash.info.roles).to eq %w(admin developer)
      end
    end

    context 'failure' do
      before(:each) do
        allow(@adaptor).to receive(:user_info).and_return(false)
      end

      context 'when ticket is not present' do
        it 'redirects to error page' do
          post('/auth/vph/callback', {})

          expect(last_response).to be_redirect
          expect(
              last_response.headers['Location']
            ).to be =~ /missing_credentials/
        end
      end

      context 'when ticket is empty' do
        it 'redirects to error page' do
          post('/auth/vph/callback', ticket: '')

          expect(last_response).to be_redirect
          expect(
              last_response.headers['Location']
            ).to be =~ /missing_credentials/
        end
      end

      context 'when username and password are present' do
        context 'and bind on master interface server failed' do
          it 'redirects to error page' do
            post('/auth/vph/callback', ticket: 'ticket_payload')

            expect(last_response).to be_redirect
            expect(
                last_response.headers['Location']
              ).to be =~ /invalid_credentials/
          end
        end
      end
    end
  end
end
