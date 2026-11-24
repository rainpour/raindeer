# frozen_string_literal: true

require 'lowevent'
require_relative 'cookies'
require_relative 'query'
require_relative 'sites'

module Rain
  module Events
    class RouteEvent < ::LowEvent
      include Cookies
      include Query
      include Sites

      attr_reader :route, :params, :request

      # Nodes observe each route's path rather than this class so they're who observes it once each across the routes.
      def self.observers(key = nil)
        return super if key

        paths = Providers['rain.router'].routes.keys - [WildcardEvent::KEY]
        Observers.of_keys { |each_key| paths.include?(each_key) }
      end

      def initialize(route:, actions: [], params: Hash | nil, request: nil)
        super(key: route.path, actions:)

        @route = route
        @params = params
        @request = request
      end
    end
  end
end
