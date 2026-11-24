# frozen_string_literal: true

module System
  # The dashboard's stats now, in the order it shows them four to a row: who's here and how busy, how quickly the app
  # answers, its memory, then the framework itself. The dashboard shows them and /system/stats sends them as JSON so
  # the dashboard can refresh them each second.
  class Stats
    # A stat with an href links its title to where it came from.
    Stat = Data.define(:key, :title, :value, :href) do
      def initialize(key:, title:, value:, href: '')
        super
      end
    end

    attr_reader :all

    def initialize
      memory = MemoryNode.current
      log = RequestLog.new
      @all = busy_row(memory) + speed_row(log) + memory_row(memory) + framework_row(memory)
    end

    # Each stat's value by its key, as text the way the dashboard shows it.
    def to_h
      all.to_h { |stat| [stat.key, stat.value.to_s] }
    end

    private

    def busy_row(memory)
      [Stat.new(key: 'uptime', title: 'Uptime', value: uptime(memory.at - MemoryNode::BOOTED_AT)),
       Stat.new(key: 'visitors', title: 'Visitors (5 min)', value: Traffic.visitors),
       Stat.new(key: 'per_second', title: 'Requests per second', value: Traffic.per_second),
       Stat.new(key: 'actions', title: 'Actions per second', value: Providers['low.event.pool'].action_rate.per_second)]
    end

    def speed_row(log)
      [Stat.new(key: 'typical', title: 'Typical response', value: milliseconds(log.typical_milliseconds)),
       Stat.new(key: 'slowest', title: 'Slowest response', value: milliseconds(log.slowest_milliseconds),
                href: '/system/requests/slowest'),
       Stat.new(key: 'connections', title: 'Open connections', value: Low::ConnectionManager.open_count),
       Stat.new(key: 'threads', title: 'Threads', value: Thread.list.size)]
    end

    def memory_row(memory)
      peak = [*MemoryNode.samples.map(&:megabytes), memory.megabytes].max
      [Stat.new(key: 'memory', title: 'Memory', value: "#{memory.megabytes} MB"),
       Stat.new(key: 'peak', title: 'Peak memory', value: "#{peak} MB"),
       Stat.new(key: 'objects', title: 'Live objects', value: Numbers.delimited(memory.objects)),
       Stat.new(key: 'retained', title: 'Retained objects', value: Numbers.delimited(memory.retained))]
    end

    def framework_row(memory)
      [Stat.new(key: 'nodes', title: 'Nodes', value: LowNode.count),
       Stat.new(key: 'collections', title: 'Garbage collections', value: Numbers.delimited(GC.count)),
       Stat.new(key: 'keys', title: 'Observed keys', value: memory.keys),
       Stat.new(key: 'busiest', title: 'Busiest second', value: Traffic.busiest_second)]
    end

    def milliseconds(value)
      return 'None yet' unless value

      "#{Numbers.delimited(value)} ms"
    end

    # How long the app has run in its two largest units, short enough to fit a card, like "3 d 4 h" or "5 min".
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
