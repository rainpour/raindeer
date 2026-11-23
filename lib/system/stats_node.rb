# frozen_string_literal: true

module System
  # The dashboard's stats now as JSON, which the dashboard fetches each second to refresh its numbers.
  class StatsNode < LowNode
    observe '/system/stats'

    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      add_header('cache-control', 'no-store')
      Stats.new.to_h
    end
  end
end
