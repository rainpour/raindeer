# frozen_string_literal: true

require 'json'
require 'uri'

module Rain
  module Events
    # A request's body. Events that include it, for requests with a body, like a form's, give it parsed as "body". It's
    # a stream that can only be read once, so it's buffered on the request for everything that reads it, like the router
    # checking a form's token and then the node it's for.
    module Body
      def self.read(request)
        return '' unless request&.body

        request.body = request.body.finish
        request.body.rewind
        request.body.join || ''
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
