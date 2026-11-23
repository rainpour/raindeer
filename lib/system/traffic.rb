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
      def request(event:)
        record(VisitorAddress.from(event.request&.headers))
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

      def per_minute(now: clock)
        @lock.synchronize { @requests.select { |second, _| now - second < MINUTE }.sum { |_, count| count } }
      end

      private

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
