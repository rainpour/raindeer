# frozen_string_literal: true

require_relative '../router/http'
require_relative '../router/events/receive_event'
require_relative '../router/events/route_event'
require_relative '../router/events/wildcard_event'
require 'lowloop'

class LowNode
  include Rain::HTTP
  include Rain::Events
  # So a node can run code periodically with "observe Interval[every_minute: 5]" and "def tick".
  Interval = Low::Loop::Interval
end
