# frozen_string_literal: true

require_relative '../router/events/cookies'

module Raindeer
  class << self
    def router(&block)
      Providers['rain.router'].instance_eval(&block)
    end

    def pages
      Providers['rain.pages']
    end

    # The request being responded to, for nodes that aren't given its event, like a layout.
    def request
      Fiber[:raindeer_request]
    end

    def cookies
      Rain::Events::Cookies.parse(request)
    end
  end
end
