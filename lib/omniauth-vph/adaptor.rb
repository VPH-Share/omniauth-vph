require 'faraday'
require 'json'

module OmniAuth
  module Vph
    class Adaptor
      class ConnectionError < StandardError; end

      MUST_HAVE_KEYS = [:host]

      attr_reader :connection

      def self.validate(configuration={})
        message = []
        MUST_HAVE_KEYS.each do |name|
           message << name if configuration[name].nil?
        end
        raise ArgumentError.new(message.join(",") +" MUST be provided") unless message.empty?
      end

      def initialize(configuration={})
        Adaptor.validate(configuration)
        @configuration = configuration.dup

        @connection = Faraday.new(url: @configuration[:host])
      end

      def user_info(ticket)
        begin
          response = @connection.get '/validatetkt/', {ticket: ticket}
          response.status == 200 ? JSON.parse(response.body) : nil
        rescue Exception => e
          raise ConnectionError.new
        end
      end

      def map_user(object)
        user = {}
        user['email'] = object['email']
        user['login'] = object['username']
        user['full_name'] = object['fullname']
        user['roles'] = roles object

        user
      end

      private

      def roles(object)
        roles_map = @configuration[:roles_map]
        roles = []
        if object['role'] and roles_map
          roles_map.each do |k,v|
            roles << v if object['role'].include? k
          end
        end
        roles
      end

    end
  end
end