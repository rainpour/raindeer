# frozen_string_literal: true

module System
  # The requests the event pool still holds, which is its last 100, newest first. Each is read from its event tree, so
  # nothing extra is kept to show them. The pool keeps the system pages' own requests and interval ticks apart.
  class RequestLog
    # A request with what it answered and how long it took. Its tree is every event it caused, from the request down.
    # Its referrer is the page that linked to it when the browser said.
    Entry = Data.define(:verb, :path, :status, :referrer, :events, :milliseconds, :seconds_ago, :root) do
      # Where to visit the page again, for a GET. A form's POST can't be visited again by following a link.
      def visit_path
        path if verb == 'GET'
      end

      def missing?
        status == 404
      end
    end

    # The request being answered now is left out as a page listing it would render the tree it's adding to forever.
    def initialize(event_trees: Providers['low.event.pool'].event_trees, answering_now: Providers['low.event.pool'].event_tree_now,
                   now: clock)
      trees = event_trees.values.reject { |tree| tree.equal?(answering_now) }
      @entries = trees.filter_map { |tree| entry(tree, now) }.sort_by(&:seconds_ago)
    end

    attr_reader :entries

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
      Entry.new(verb: root.request.method, path: root.request.path, status: status(events),
                referrer: root.request.headers['referer'], events: events.size,
                milliseconds: (events.last.created_at - root.created_at).round,
                seconds_ago: ((now - root.created_at) / 1000).floor,
                root:)
    end

    # The status of the last response the request made, or nil while it's still answering.
    def status(events)
      events.reverse.find { |event| event.is_a?(Low::Events::ResponseEvent) }&.response&.status
    end

    # Events are timed in milliseconds from the same clock.
    def clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end
  end
end
