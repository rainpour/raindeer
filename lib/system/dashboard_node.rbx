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

    # The stats are four across: who's here and how busy, how quickly it answers, memory, then the framework itself.
    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <h1>{"Dashboard"}</h1>

        <div class="stats">
          <{ StatFormatter title='Uptime' stat=@uptime }>
          <{ StatFormatter title='Visitors in the last 5 minutes' stat=@visitors }>
          <{ StatFormatter title='Requests in the last minute' stat=@per_minute }>
          <{ StatFormatter title='Answering now' stat=@answering }>

          <{ StatFormatter title='Typical response' stat=@typical }>
          <{ StatFormatter title='Slowest response' stat=@slowest }>
          <{ StatFormatter title='Open connections' stat=@connections }>
          <{ StatFormatter title='Threads' stat=@threads }>

          <{ StatFormatter title='Memory' stat=@memory }>
          <{ StatFormatter title='Peak memory' stat=@peak }>
          <{ StatFormatter title='Live objects' stat=@objects }>
          <{ StatFormatter title='Garbage collections' stat=@collections }>

          <{ StatFormatter title='Nodes' stat=@node_count }>
          <{ StatFormatter title='Events' stat=@event_count }>
          <{ StatFormatter title='Observed keys' stat=@keys }>
          <{ StatFormatter title='Requests kept' stat=@kept }>
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
      @per_minute = Traffic.per_minute
      @visitors = Traffic.visitors
      @answering = log.answering
      @kept = log.entries.size
      @typical = milliseconds(log.typical_milliseconds)
      @slowest = milliseconds(log.slowest_milliseconds)
    end

    def ruby_stats
      @threads = Thread.list.size
      @connections = Low::ConnectionManager.open_count
      @objects = Numbers.delimited(GC.stat(:heap_live_slots))
      @collections = Numbers.delimited(GC.count)
    end

    def milliseconds(value)
      return 'None yet' unless value

      "#{Numbers.delimited(value)} ms"
    end

    # How long the process has run in its two largest units, short enough to fit a card, like "3 d 4 h" or "5 min".
    def uptime(seconds)
      units = { 'd' => 86_400, 'h' => 3600, 'min' => 60 }
      parts = units.filter_map do |name, size|
        count = (seconds / size).floor
        seconds -= count * size
        "#{count} #{name}" if count.positive?
      end
      return '< 1 min' if parts.empty?

      parts.first(2).join(' ')
    end
  end
end
