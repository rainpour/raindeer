# frozen_string_literal: true

module System
  class DashboardNode < LowNode
    observe '/system'

    def initialize(event:)
      @stats = Stats.new.all
      # Each trend ends with now so it has a line before the first sample after the app starts.
      samples = [*MemoryNode.samples, MemoryNode.current]
      @megabytes = samples.map(&:megabytes)
      @key_counts = samples.map(&:keys)
      @object_counts = samples.map(&:objects)
      @retained_counts = samples.map(&:retained)
    end

    # The stats four across, in Stats' order, which refresh each second, then the intervals and trends.
    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <div class="stats">
          <{ for: stat in: @stats }>
            <{ StatFormatter title=stat.title stat=stat.value key=stat.key href=stat.href }>
          <{ :for }>
        </div>

        <h2>{"Intervals"}</h2>
        <{ IntervalsFormatter }>

        <h2>{"Trends"}</h2>
        <div class="trends">
          <{ TrendFormatter title='Memory in MB each minute' values=@megabytes }>
          <{ TrendFormatter title='Observed keys each minute' values=@key_counts }>
          <{ TrendFormatter title='Live objects each minute' values=@object_counts }>
          <{ TrendFormatter title='Retained objects each minute' values=@retained_counts }>
        </div>
      <{ :LayoutNode }>
    end
  end
end
