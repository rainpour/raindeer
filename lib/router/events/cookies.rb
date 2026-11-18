# frozen_string_literal: true

require 'uri'

module Rain
  module Events
    # The cookies a request sent, by name, for the events made from it.
    module Cookies
      def self.parse(request)
        Array(request&.headers&.[]('cookie')).flat_map { |header| header.split(';') }.to_h do |cookie|
          name, value = cookie.strip.split('=', 2)
          [name, URI.decode_www_form_component(value.to_s)]
        end
      end

      def cookies
        @cookies ||= Cookies.parse(request)
      end
    end
  end
end
