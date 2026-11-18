# frozen_string_literal: true

require 'lowevent'
require 'uri'

module Rain
  module Events
    # The cookies a request sent, by name, for the events made from it, like a RouteEvent or a child node's RenderEvent.
    module Cookies
      def cookies
        Array(request&.headers&.[]('cookie')).flat_map { |header| header.split(';') }.to_h do |cookie|
          name, value = cookie.strip.split('=', 2)
          [name, URI.decode_www_form_component(value.to_s)]
        end
      end
    end

    Low::Events::RenderEvent.include(Cookies)
  end
end
