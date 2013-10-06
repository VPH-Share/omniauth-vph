require 'multi_json'
require 'omniauth'

module OmniAuth
  module Strategies
    class Vph
      include OmniAuth::Strategy

      option :title, 'VPH-Share Master Interface Ticket Authentication' #default title for authentication form
      option :host

      option :roles_map

      def request_phase
        OmniAuth::Vph::Adaptor.validate @options
        f = OmniAuth::Form.new(:title => (options[:title] || 'VPH-Share Master Interface Ticket Authentication'), :url => callback_path)
        f.password_field 'Ticket', 'ticket'
        f.button "Sign In"
        f.to_response
      end

      def callback_phase
        @adaptor = OmniAuth::Vph::Adaptor.new @options

        return fail!(:missing_credentials) if missing_credentials?
        begin
          @mi_user_info = @adaptor.user_info request['ticket']
          return fail!(:invalid_credentials) if !@mi_user_info

          @user_info = map_user(@mi_user_info)
          super
        rescue Exception => e
          return fail!(:master_interface_error, e)
        end
      end

      uid {
        @user_info["login"]
      }

      info {
        @user_info
      }

      extra {
        { :raw_info => @mi_user_info }
      }

      protected

      def map_user(object)
        user = {}
        user['email'] = object['email']
        user['login'] = object['username']
        user['full_name'] = object['fullname']
        user['roles'] = roles object

        user
      end

      def roles(object)
        roles_map = @options[:roles_map]
        roles = []
        if object['role'] and roles_map
          roles_map.each do |k,v|
            roles << v if object['role'].include? k
          end
        end
        roles
      end

      def missing_credentials?
        request['ticket'].nil? or request['ticket'].empty?
      end
    end
  end
end