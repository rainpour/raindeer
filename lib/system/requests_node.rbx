# frozen_string_literal: true

module System
  # The last requests the event pool holds, newest first. Open one to see where its time went as a bar and every event
  # it caused in the order they branched from the request.
  class RequestsNode < LowNode
    observe '/system/requests'

    # Found requests show by default and ?show=missing shows the 404s.
    def initialize(event:)
      missing = event.query[:show] == 'missing'
      @entries = RequestLog.new.entries.select { |entry| entry.missing? == missing }
      @found = (!missing).to_s
      @missing = missing.to_s
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
          </div>
        </div>

        <{ if: @empty }>
          <p>{"None yet."}</p>
        <{ :if }>

        <{ for: entry in: @entries }>
          <details class="request">
            <summary>
              <code>{entry.verb}</code>{" "}<strong>{entry.path}</strong>
              <small>{" "}{entry.status}{" · "}{entry.milliseconds}{" ms · "}{entry.events}{" events · "}{entry.seconds_ago}{" s ago"}</small>
              <{ if: entry.referrer }>
                <small class="referrer">{"from "}{entry.referrer}</small>
              <{ :if }>
              <{ if: entry.visit_path }>
                <a class="visit" href="{entry.visit_path}" role="button">{"Visit"}</a>
              <{ :if }>
            </summary>
            <{ LifecycleFormatter root=entry.root }>
            <ul class="tree">
              <{ BranchFormatter branch=entry.root }>
            </ul>
          </details>
        <{ :for }>
      <{ :LayoutNode }>
    end
  end
end
