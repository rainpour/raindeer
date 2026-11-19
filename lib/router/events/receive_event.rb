# frozen_string_literal: true

require_relative 'body'
require_relative 'route_event'

module Rain
  module Events
    # A RouteEvent for a request with a body, which calls the "receive" action.
    class ReceiveEvent < RouteEvent
      include Body

      def initialize(route:, request:, actions: [], params: Hash | nil)
        super
      end
    end
  end
end
