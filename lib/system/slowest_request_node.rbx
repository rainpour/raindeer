# frozen_string_literal: true

module System
  # The slowest of the requests the event pool holds, open to show where its time went. The dashboard's slowest
  # response links here.
  class SlowestRequestNode < LowNode
    observe '/system/requests/slowest'

    def initialize(event:) # rubocop:disable Lint/UnusedMethodArgument
      @entry = RequestLog.new.slowest
      @empty = @entry.nil?
      @kept = Low::Events::EventPool::BUFFER_SIZE
    end

    def render(event:) # rubocop:disable Lint/UnusedMethodArgument
      <{ LayoutNode: }>
        <p class="lede">{"The slowest of the last "}{@kept}{" requests"}</p>

        <{ if: @empty }>
          <p>{"None yet."}</p>
        <{ :if }>

        <{ if: @entry }>
          <details class="request" open>
            <{ RequestFormatter entry=@entry }>
          </details>
        <{ :if }>
      <{ :LayoutNode }>
    end
  end
end
