# frozen_string_literal: true

require 'openssl'

module System
  # Who's visiting and how busy the app is, counted as each request comes in, so it isn't limited to the event pool's
  # last 100. A visitor is a different address seen in the last 5 minutes. Each is kept as a hash with a key made when
  # the app starts, so the server doesn't keep a list of visitors' addresses.
  class Traffic
    WINDOW = 300
    MINUTE = 60
    KEY = OpenSSL::Random.random_bytes(32)

    @seen = {}
    @requests = Hash.new(0)
    @lock = Mutex.new

    class << self
      # Counts a request on its way in and passes it on, so the next observer answers it.
      # The system pages aren't counted, so the dashboard refreshing itself each second doesn't count as traffic.
      def request(event:)
        request = event.request
        record(VisitorAddress.from(request&.headers)) unless request&.path.to_s.start_with?('/system')
        nil
      end

      def record(address, now: clock)
        @lock.synchronize do
          @seen[digest(address)] = now if address
          @requests[now.floor] += 1
          forget(now)
        end
      end

      def visitors(now: clock)
        @lock.synchronize { @seen.count { |_, seen_at| now - seen_at < WINDOW } }
      end

      # Requests a second on average over the last minute, so one busy moment doesn't make it jump.
      def per_second(now: clock)
        (last_minute(now).sum / MINUTE.to_f).round(1)
      end

      # The most requests in any one second in the last minute, which shows a burst the average smooths over.
      def busiest_second(now: clock)
        last_minute(now).max || 0
      end

      private

      # How many requests came in each second of the last minute.
      def last_minute(now)
        @lock.synchronize { @requests.select { |second, _| now - second < MINUTE }.values }
      end

      # Drops visitors not seen for 5 minutes and seconds over a minute ago, so memory stays small however busy it gets.
      # Once a second is enough, so a busy app doesn't go through them on every request.
      def forget(now)
        return if @forgot_at && now - @forgot_at < 1

        @forgot_at = now
        @seen.delete_if { |_, seen_at| now - seen_at >= WINDOW }
        @requests.delete_if { |second, _| now - second >= MINUTE }
      end

      def digest(address)
        OpenSSL::HMAC.digest('SHA256', KEY, address).byteslice(0, 16)
      end

      def clock
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
