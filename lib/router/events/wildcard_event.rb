# frozen_string_literal: true

require 'lowevent'
require_relative 'body'
require_relative 'cookies'
require_relative 'query'

module Rain
  module Events
    # An event for a path no route has, which nodes observing "/*" look up, like a page's. A request with a body, like a
    # form's, calls their "receive" action with it.
    class WildcardEvent < ::LowEvent
      KEY = '/*'
      include Body
      include Cookies
      include Query

      attr_reader :route, :params, :request

      # Nodes observe the "/*" path rather than this class so they're who observes it.
      def self.observers(key = KEY)
        super
      end

      def initialize(key:, route:, action: :render, request: nil)
        super(key:, action:)

        @route = route
        @request = request
      end
    end
  end
end
