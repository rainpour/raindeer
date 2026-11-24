# frozen_string_literal: true

require 'lowevent'
require 'protocol/http'
require_relative 'visitor_address'

module Rain
  # Turns away a visitor who asks for a path too often, like a search that queries the database each time, before it
  # reaches the router. Each path under rate_limits in config.yaml has the requests a minute each visitor may make to
  # it and the paths under it. A visitor is their address as a proxy like Cloudflare or Caddy passes it on, so a request
  # without one, like while developing, isn't limited. It's kept in memory, so it's per process.
  module RateLimit
    MINUTE = 60

    @counts = {}
    @lock = Mutex.new

    class << self
      # A request over its path's limit goes no further than a 429: the app's page for it, or a plain one when it has none.
      def request(event:)
        request = event.request
        path, limit = limit_for(request.path.to_s.split('?').first.to_s)
        address = VisitorAddress.from(request.headers) if limit
        return unless address

        wait = wait_for("#{address} #{path}", limit:)
        too_many(request, wait:) if wait
      end

      # Seconds until the visitor may ask again, or nil while they're within the limit. Each counts afresh each minute.
      def wait_for(key, limit:, now: clock)
        minute = (now / MINUTE).floor
        @lock.synchronize do
          forget(minute)
          count = @counts[key]&.fetch(minute, 0).to_i + 1
          @counts[key] = { minute => count }
          ((minute + 1) * MINUTE - now).ceil if count > limit
        end
      end

      private

      # The limited path a request is to or under, and its limit.
      def limit_for(path)
        limits = Providers['rain.config'].rate_limits || {}
        limits.find { |limited, _| path == limited.to_s || path.start_with?("#{limited.to_s.chomp('/')}/") }
      end

      # Drops counts from minutes before this one once a minute, so memory stays small however many visitors come.
      def forget(minute)
        return if @forgot_at == minute

        @forgot_at = minute
        @counts.delete_if { |_, counts| !counts.key?(minute) }
      end

      def too_many(request, wait:)
        response = Low::Events::StatusEvent.take(status: Low::Types::Status[429], request:) || plain_response
        response.response.headers.add('retry-after', wait.to_s)
        response
      end

      def plain_response
        headers = Protocol::HTTP::Headers[{ 'content-type' => 'text/plain' }]
        body = Protocol::HTTP::Body::Buffered.wrap("That's a lot of requests. Try again in a minute.\n")
        Low::Events::ResponseEvent.new(response: Protocol::HTTP::Response.new('HTTP/1.1', 429, headers, body))
      end

      def clock
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
