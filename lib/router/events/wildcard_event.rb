# frozen_string_literal: true

require 'lowevent'
require_relative 'cookies'

module Rain
  module Events
    class WildcardEvent < ::LowEvent
      include Cookies

      attr_reader :route, :params, :request

      def initialize(key:, route:, action: :render, request: nil)
        super(key:, action:)

        @route = route
        @request = request
      end
    end
  end
end
