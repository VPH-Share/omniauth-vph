require 'multi_json'
require 'omniauth'

module OmniAuth
  module Strategies
    #
    # Vph user ticket omniauth strategy.
    #
    class Vphticket
      include OmniAuth::Strategy
      DEFAULT_TITLE = 'VPH-Share Master Interface Ticket Authentication'

      option :title,  DEFAULT_TITLE
      option :host

      option :roles_map

      def request_phase
        OmniAuth::Vph::Adaptor.validate @options
        f = OmniAuth::Form.new(
              title: (options[:title] || DEFAULT_TITLE),
              url: callback_path
            )
        f.password_field 'Ticket', 'ticket'
        f.button 'Sign In'
        f.to_response
      end

      def callback_phase
        @adaptor = OmniAuth::Vph::Adaptor.new @options

        return fail!(:missing_credentials) if missing_credentials?
        begin
          @mi_user_info = @adaptor.user_info request['ticket']
          return fail!(:invalid_credentials) unless @mi_user_info

          @user_info = @adaptor.map_user(@mi_user_info)
          super
        rescue => e
          return fail!(:master_interface_error, e)
        end
      end

      uid { @user_info['login'] }
      info { @user_info }
      extra { { raw_info: @mi_user_info } }

      def missing_credentials?
        request['ticket'].nil? || request['ticket'].empty?
      end
    end
  end
end
