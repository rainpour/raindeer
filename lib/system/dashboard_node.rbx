# frozen_string_literal: true

module System
  class DashboardNode < LowNode
    observe '/system'

    def initialize(event:)
      @node_count = LowNode.count
      @event_count = LowEvent.count
      memory_stats
      request_stats
      ruby_stats
    end

    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <h1>{"Dashboard"}</h1>

        <div class="grid">
          <{ StatFormatter title='Nodes' stat=@node_count }>
          <{ StatFormatter title='Events' stat=@event_count }>
          <{ StatFormatter title='Uptime' stat=@uptime }>
        </div>

        <div class="grid">
          <{ StatFormatter title='Memory' stat=@memory }>
          <{ StatFormatter title='Peak memory' stat=@peak }>
          <{ StatFormatter title='Observed keys' stat=@keys }>
        </div>

        <div class="grid">
          <{ StatFormatter title='Requests in the last minute' stat=@per_minute }>
          <{ StatFormatter title='Typical response' stat=@typical }>
          <{ StatFormatter title='Slowest response' stat=@slowest }>
        </div>

        <div class="grid">
          <{ StatFormatter title='Threads' stat=@threads }>
          <{ StatFormatter title='Live objects' stat=@objects }>
          <{ StatFormatter title='Garbage collections' stat=@collections }>
        </div>

        <{ if: @trend }>
          <{ TrendFormatter title='Memory in MB each minute' values=@megabytes }>
          <{ TrendFormatter title='Observed keys each minute' values=@key_counts }>
          <{ TrendFormatter title='Live objects each minute' values=@object_counts }>
        <{ :if }>

        <h2>{"Intervals"}</h2>
        <{ IntervalsFormatter }>
      <{ :LayoutNode }>
    end

    private

    # The memory and keys now, and each minute's since the app started, for the trend lines.
    def memory_stats
      now = MemoryNode.current
      samples = MemoryNode.samples
      @memory = "#{now.megabytes} MB"
      @peak = "#{[*samples.map(&:megabytes), now.megabytes].max} MB"
      @keys = now.keys
      @uptime = uptime(now.at - MemoryNode::BOOTED_AT)
      @trend = samples.size > 1
      @megabytes = samples.map(&:megabytes)
      @key_counts = samples.map(&:keys)
      @object_counts = samples.map(&:objects)
    end

    # How busy the app is and how quickly it answers, from the requests the event pool still holds.
    def request_stats
      log = RequestLog.new
      @per_minute = log.per_minute
      @typical = milliseconds(log.typical_milliseconds)
      @slowest = milliseconds(log.slowest_milliseconds)
    end

    def ruby_stats
      @threads = Thread.list.size
      @objects = Numbers.delimited(GC.stat(:heap_live_slots))
      @collections = Numbers.delimited(GC.count)
    end

    def milliseconds(value)
      return 'None yet' unless value

      "#{Numbers.delimited(value)} ms"
    end

    # How long the process has run, in its two largest units, like "2 days 3 hours" or "5 minutes".
    def uptime(seconds)
      units = { 'day' => 86_400, 'hour' => 3600, 'minute' => 60 }
      parts = units.filter_map do |name, size|
        count = (seconds / size).floor
        seconds -= count * size
        "#{count} #{name}#{'s' unless count == 1}" if count.positive?
      end
      return 'Under a minute' if parts.empty?

      parts.first(2).join(' ')
    end
  end
end
