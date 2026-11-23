# frozen_string_literal: true

module System
  # The process's memory and how many keys Observers holds and how many objects Ruby holds, sampled each minute for the
  # last 3 hours. The dashboard shows them so you can see if any keeps climbing. Live objects rise and fall with each
  # garbage collection. Retained objects have survived several, so when they keep climbing it's a leak.
  class MemoryNode < LowNode
    observe Interval[every_minute: 1]

    Sample = Data.define(:at, :megabytes, :keys, :objects, :retained)

    KEPT = 180
    STATUS = '/proc/self/status'
    BOOTED_AT = Time.now

    @samples = []
    @lock = Mutex.new

    class << self
      # The samples so far, oldest first. The interval's thread adds them while requests read them.
      def samples
        @lock.synchronize { @samples.dup }
      end

      def record(sample)
        @lock.synchronize do
          @samples << sample
          @samples.shift while @samples.size > KEPT
        end
      end

      def current
        Sample.new(at: Time.now, megabytes:, keys: Observers::Keys.keys.size, objects: GC.stat(:heap_live_slots),
                   retained: GC.stat(:old_objects))
      end

      # The memory the process holds now in megabytes. Linux has it in /proc and other systems like macOS give it to ps.
      def megabytes
        return File.read(STATUS)[/VmRSS:\s+(\d+)/, 1].to_i / 1024 if File.exist?(STATUS)

        `ps -o rss= -p #{Process.pid}`.to_i / 1024
      end
    end

    def tick
      self.class.record(self.class.current)
    end
  end
end
