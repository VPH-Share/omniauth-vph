require 'faraday'
require 'json'

module OmniAuth
  module Vph
    #
    # Addaptor, which connects to Master Interface and get
    # user details from user ticket.
    #
    class Adaptor
      class ConnectionError < StandardError; end

      MUST_HAVE_KEYS = [:host]

      attr_reader :connection

      def self.validate(configuration = {})
        message = []
        MUST_HAVE_KEYS.each do |name|
          message << name if configuration[name].nil?
        end
        fail(
          ArgumentError,
          "#{message.join(",")} MUST be provided"
        ) unless message.empty?
      end

      def initialize(configuration = {})
        Adaptor.validate(configuration)
        @configuration = configuration.dup

        @connection = Faraday.new(
                        url: @configuration[:host],
                        ssl: { verify: ssl_verify? }
                      )
      end

      def user_info(ticket)
        response = @connection.get '/validatetkt/', ticket: ticket
        response.status == 200 ? JSON.parse(response.body) : nil
      rescue
        raise ConnectionError, 'Unable to connect to Master Interface'
      end

      def map_user(object)
        {
          'email' => object['email'],
          'login' => object['username'],
          'full_name' => object['fullname'],
          'roles' => roles(object)
        }
      end

      private

      def ssl_verify?
        @configuration[:ssl_verify].nil? ? true : @configuration[:ssl_verify]
      end

      def roles(object)
        roles_map = @configuration[:roles_map]
        roles = []
        if object['role'] && roles_map
          roles_map.each do |k, v|
            roles << v if object['role'].include? k
          end
        end
        roles
      end
    end
  end
end
