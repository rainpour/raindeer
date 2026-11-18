# frozen_string_literal: true

require 'lowevent'
require_relative 'cookies'
require_relative 'query'

module Rain
  module Events
    class WildcardEvent < ::LowEvent
      include Cookies
      include Query

      attr_reader :route, :params, :request

      def initialize(key:, route:, action: :render, request: nil)
        super(key:, action:)

        @route = route
        @request = request
      end
    end
  end
end
