# frozen_string_literal: true

require 'lowevent'
require_relative 'cookies'
require_relative 'query'

module Rain
  module Events
    class RouteEvent < ::LowEvent
      include Cookies
      include Query

      attr_reader :route, :params, :request

      # Nodes observe each route's path rather than this class so they're who observes it once each across the routes.
      def self.observers(key = nil)
        return super if key

        paths = Providers['rain.router'].routes.keys - [WildcardEvent::KEY]
        paths.flat_map { |path| super(path).to_a }.uniq(&:object)
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
