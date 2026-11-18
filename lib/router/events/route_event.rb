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

      def initialize(route:, actions: [], params: Hash | nil, request: nil)
        super(key: route.path, actions:)

        @route = route
        @params = params
        @request = request
      end
    end
  end
end
