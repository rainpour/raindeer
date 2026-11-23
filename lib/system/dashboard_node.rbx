# frozen_string_literal: true

module System
  class DashboardNode < LowNode
    observe '/system'

    def initialize(event:)
      @node_count = LowNode.count
      @event_count = LowEvent.count

      now = MemoryNode.current
      samples = MemoryNode.samples
      @memory = "#{now.megabytes} MB"
      @peak = "#{[*samples.map(&:megabytes), now.megabytes].max} MB"
      @keys = now.keys
      @uptime = uptime(now.at - MemoryNode::BOOTED_AT)
      @trend = samples.size > 1
      @megabytes = samples.map(&:megabytes)
      @key_counts = samples.map(&:keys)
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

        <{ if: @trend }>
          <{ TrendFormatter title='Memory in MB each minute' values=@megabytes }>
          <{ TrendFormatter title='Observed keys each minute' values=@key_counts }>
        <{ :if }>
      <{ :LayoutNode }>
    end

    private

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
