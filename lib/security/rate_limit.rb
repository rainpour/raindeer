# frozen_string_literal: true

require 'lowevent'
require 'protocol/http'
require_relative 'visitor_address'

module Rain
  # Turns away a visitor who asks for pages too often, like a search that queries the database each time, before the
  # router answers. Files are answered before it, so they don't count. Each path under rate_limits in config.yaml has
  # the requests a minute each visitor may make to it and the paths under it. The most specific path's limit applies,
  # so / can limit every page and /search less. A visitor is their address as a proxy like Cloudflare or Caddy passes
  # it on, so a request without one, like while developing, isn't limited. It's kept in memory, so it's per process.
  module RateLimit
    MINUTE = 60
    # The minutes the dashboard counts denied requests over, which is a day.
    DAY = 24 * 60

    @counts = {}
    @denied = Hash.new(0)
    @lock = Mutex.new

    class << self
      # A request over its path's limit goes no further than a 429: the app's page for it, or a plain one when it has none.
      # The system pages don't count, as the dashboard refreshes itself each second.
      def request(event:)
        request = event.request
        page = request.path.to_s.split('?').first.to_s
        return if page == '/system' || page.start_with?('/system/')

        path, limit = limit_for(page)
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
          next if count <= limit

          @denied[minute] += 1
          ((minute + 1) * MINUTE - now).ceil
        end
      end

      # How many requests were denied in the last 24 hours.
      def denied(now: clock)
        minute = (now / MINUTE).floor
        @lock.synchronize { @denied.select { |at, _| minute - at < DAY }.values.sum }
      end

      private

      # The most specific limited path a request is to or under, and its limit.
      def limit_for(path)
        limits = Providers['rain.config'].rate_limits || {}
        matches = limits.select { |limited, _| path == limited.to_s || path.start_with?("#{limited.to_s.chomp('/')}/") }
        matches.max_by { |limited, _| limited.to_s.length }
      end

      # Drops counts from minutes before this one, and denials from over a day ago, once a minute. Denials are counted
      # by the minute, so memory stays small however many visitors come.
      def forget(minute)
        return if @forgot_at == minute

        @forgot_at = minute
        @counts.delete_if { |_, counts| !counts.key?(minute) }
        @denied.delete_if { |at, _| minute - at >= DAY }
      end

      def too_many(request, wait:)
        response = Low::Events::StatusEvent.take(status: Low::Types::Status[429], request:) || plain_response
        response.response.headers.add('retry-after', wait.to_s)
        response
      end

      # It joins the request's events, as the app's own page would, so the requests page shows it was turned away.
      def plain_response
        headers = Protocol::HTTP::Headers[{ 'content-type' => 'text/plain' }]
        body = Protocol::HTTP::Body::Buffered.wrap("That's a lot of requests. Try again in a minute.\n")
        response = Low::Events::ResponseEvent.new(response: Protocol::HTTP::Response.new('HTTP/1.1', 429, headers, body))
        response.record { nil }
        response
      end

      def clock
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
