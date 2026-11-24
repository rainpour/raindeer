# frozen_string_literal: true

module System
  class DashboardNode < LowNode
    observe '/system'

    def initialize(event:)
      @stats = Stats.new.all
      @segments = Lifecycle.new.segments
      @lifecycle = @segments.any?
      samples = MemoryNode.samples
      @trend = samples.size > 1
      @megabytes = samples.map(&:megabytes)
      @key_counts = samples.map(&:keys)
      @object_counts = samples.map(&:objects)
      @retained_counts = samples.map(&:retained)
    end

    # An average request's events as a bar then the stats four across in Stats' order which refresh each second. Then the
    # trends and intervals.
    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <{ if: @lifecycle }>
          <a class="lifecycle" href="/system/requests" title="Where an average request spends its time">
            <{ for: segment in: @segments }>
              <span style="flex-grow: {segment.milliseconds}" title="{segment.label}"><span>{segment.name}{" "}<small>{segment.duration}</small></span></span>
            <{ :for }>
          </a>
        <{ :if }>

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
            <{ TrendFormatter title='Retained objects each minute' values=@retained_counts }>
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
