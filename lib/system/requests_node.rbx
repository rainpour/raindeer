# frozen_string_literal: true

module System
  # The last requests the event pool holds, newest first. Open one to see every event it caused, in the order they
  # branched from the request.
  class RequestsNode < LowNode
    observe '/system/requests'

    def initialize(event:)
      @entries = RequestLog.new.entries
      @empty = @entries.empty?
    end

    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <h1>{"Requests"}</h1>
        <p>{"The last 100 requests, newest first. Open one to see every event it caused."}</p>

        <{ if: @empty }>
          <p>{"No requests yet."}</p>
        <{ :if }>

        <{ for: entry in: @entries }>
          <details class="request">
            <summary>
              <code>{entry.verb}</code>{" "}<strong>{entry.path}</strong>
              <small>{" "}{entry.status}{" · "}{entry.milliseconds}{" ms · "}{entry.events}{" events · "}{entry.seconds_ago}{" s ago"}</small>
              <{ if: entry.visit_path }>
                <a class="visit" href="{entry.visit_path}" role="button">{"Visit"}</a>
              <{ :if }>
            </summary>
            <ul class="tree">
              <{ BranchFormatter branch=entry.root }>
            </ul>
          </details>
        <{ :for }>
      <{ :LayoutNode }>
    end
  end
end
