# frozen_string_literal: true

module System
  # The requests the event pool still holds, which is its last 100, newest first. Each is read from its event tree, so
  # nothing extra is kept to show them. Trees an interval started aren't requests and are left out.
  class RequestLog
    # A request with what it answered and how long it took. Its tree is every event it caused, from the request down.
    Entry = Data.define(:verb, :path, :status, :events, :milliseconds, :seconds_ago, :address, :root) do
      # Where to visit the page again, for a GET. A form's POST can't be visited again by following a link.
      def visit_path
        path if verb == 'GET'
      end
    end

    MINUTE = 60_000
    # Where a proxy like Cloudflare or Caddy says a request came from, first match first.
    ADDRESS_HEADERS = %w[cf-connecting-ip x-forwarded-for x-real-ip].freeze

    def initialize(event_trees: Providers['low.event.pool'].event_trees, now: clock)
      @entries = event_trees.values.filter_map { |tree| entry(tree, now) }.sort_by(&:seconds_ago)
    end

    attr_reader :entries

    def per_minute
      @entries.count { |entry| entry.seconds_ago * 1000 < MINUTE }
    end

    # The different addresses requests came from in the last 5 minutes, which is as close as HTTP gets to people here now.
    def visitors
      @entries.select { |entry| entry.seconds_ago < 300 }.filter_map(&:address).uniq.size
    end

    # Requests still being answered, which haven't made their response yet.
    def answering
      @entries.count { |entry| entry.status.nil? }
    end

    # The middle request's time, so a few slow ones don't skew it.
    def typical_milliseconds
      times = @entries.map(&:milliseconds).sort
      times[times.size / 2]
    end

    def slowest_milliseconds
      @entries.map(&:milliseconds).max
    end

    private

    def entry(tree, now)
      root = tree.root_event
      return unless root.is_a?(Low::Events::RequestEvent)

      events = tree.sequence.dup
      Entry.new(verb: root.request.method, path: root.request.path, status: status(events), events: events.size,
                milliseconds: events.last.created_at - root.created_at, seconds_ago: (now - root.created_at) / 1000,
                address: address(root.request.headers), root:)
    end

    # The status of the last response the request made, or nil while it's still answering.
    def status(events)
      events.reverse.find { |event| event.is_a?(Low::Events::ResponseEvent) }&.response&.status
    end

    # The first address the first header names, as x-forwarded-for lists each proxy after the visitor.
    def address(headers)
      header = ADDRESS_HEADERS.find { |name| headers&.include?(name) }
      return unless header

      Array(headers[header]).join(',').split(',').first&.strip
    end

    # Events are timed in milliseconds from the same clock.
    def clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end
  end
end
