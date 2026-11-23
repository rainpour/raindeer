# frozen_string_literal: true

module System
  class DashboardNode < LowNode
    observe '/system'

    def initialize(event:)
      @stats = Stats.new.all
      samples = MemoryNode.samples
      @trend = samples.size > 1
      @megabytes = samples.map(&:megabytes)
      @key_counts = samples.map(&:keys)
      @object_counts = samples.map(&:objects)
    end

    # The stats four across, in Stats' order, which refresh each second, then the trends and intervals.
    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <p class="lede">{"How the app is doing now. The numbers refresh each second."}</p>

        <div class="stats">
          <{ for: stat in: @stats }>
            <{ StatFormatter title=stat.title stat=stat.value key=stat.key }>
          <{ :for }>
        </div>

        <{ if: @trend }>
          <h2>{"Trends"}</h2>
          <div class="trends">
            <{ TrendFormatter title='Memory in MB each minute' values=@megabytes }>
            <{ TrendFormatter title='Observed keys each minute' values=@key_counts }>
            <{ TrendFormatter title='Live objects each minute' values=@object_counts }>
          </div>
        <{ :if }>

        <h2>{"Intervals"}</h2>
        <div class="panel">
          <{ IntervalsFormatter }>
        </div>
      <{ :LayoutNode }>
    end
  end
end
