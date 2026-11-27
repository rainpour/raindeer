# frozen_string_literal: true

module System
  # The last requests the event pool holds, newest first. Open one to see where its time went as a bar and every event
  # it caused in the order they branched from the request.
  class RequestsNode < LowNode
    observe '/system/requests'

    # Found requests show by default, ?show=missing shows the 404s and ?show=denied those a rate limit turned away. The
    # rate limit keeps its own last 100 so they're still listed once the pool has moved on, like the stat's day of them.
    def initialize(event:)
      list = event.query[:show].to_s
      list = 'found' unless RequestLog::LISTS.value?(list)
      trees = Providers['low.event.pool'].event_trees
      trees = Rain::RateLimit.denied_trees if list == 'denied'
      @entries = RequestLog.new(event_trees: trees).entries.select { |entry| entry.list == list }
      @found = (list == 'found').to_s
      @missing = (list == 'missing').to_s
      @denied = (list == 'denied').to_s
      @kept = Low::Events::EventPool::BUFFER_SIZE
      @empty = @entries.empty?
    end

    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <div class="intro">
          <p class="lede">{"The last "}{@kept}{" requests"}</p>
          <div class="pills">
            <a href="/system/requests" aria-current="{@found}">{"Found"}</a>
            <a href="/system/requests?show=missing" aria-current="{@missing}">{"Missing"}</a>
            <a href="/system/requests?show=denied" aria-current="{@denied}">{"Denied"}</a>
          </div>
        </div>

        <{ if: @empty }>
          <p>{"None yet."}</p>
        <{ :if }>

        <{ for: entry in: @entries }>
          <details class="request">
            <{ RequestFormatter entry=entry }>
          </details>
        <{ :for }>
      <{ :LayoutNode }>
    end
  end
end
