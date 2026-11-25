# frozen_string_literal: true

module System
  # The last requests the event pool holds, newest first. Open one to see where its time went as a bar and every event
  # it caused in the order they branched from the request.
  class RequestsNode < LowNode
    observe '/system/requests'

    # Found requests show by default, ?show=missing shows the 404s and ?show=limited those a rate limit turned away.
    def initialize(event:)
      list = event.query[:show].to_s
      list = 'found' unless RequestLog::LISTS.value?(list)
      @entries = RequestLog.new.entries.select { |entry| entry.list == list }
      @found = (list == 'found').to_s
      @missing = (list == 'missing').to_s
      @limited = (list == 'limited').to_s
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
            <a href="/system/requests?show=limited" aria-current="{@limited}">{"Limited"}</a>
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
