# frozen_string_literal: true

module System
  # The dashboard's stats now as JSON with its interval pills' outcomes, which the dashboard fetches each second to
  # refresh them.
  class StatsNode < LowNode
    observe '/system/stats'

    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      add_header('cache-control', 'no-store')
      Stats.new.to_h.merge('intervals' => IntervalsFormatter.outcomes)
    end
  end
end
