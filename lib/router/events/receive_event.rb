# frozen_string_literal: true

require 'json'
require 'uri'
require_relative 'body'
require_relative 'route_event'

module Rain
  module Events
    # A RouteEvent for a request with a body, which calls the "receive" action.
    class ReceiveEvent < RouteEvent
      def initialize(route:, request:, actions: [], params: Hash | nil)
        super
      end

      def raw_body
        @raw_body ||= Body.read(@request)
      end

      # Form and JSON bodies become a hash with symbol keys, other bodies are the raw string.
      def body
        return @body if defined?(@body) # Also keeps a falsy body like JSON "null".

        @body = case media_type
                when 'application/x-www-form-urlencoded' then URI.decode_www_form(raw_body).to_h.transform_keys(&:to_sym)
                when 'application/json' then JSON.parse(raw_body, symbolize_names: true)
                else raw_body
                end
      end

      private

      def media_type = @request.headers['content-type']&.split(';')&.first&.strip
    end
  end
end
