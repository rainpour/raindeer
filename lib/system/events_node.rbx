# frozen_string_literal: true

module System
  class EventsNode < LowNode
    observe '/system/events'

    def initialize(event:)
      # TODO: Include types that can be observed keys too like Status and Status[404].
      @event_types = LowEvent.events
    end

    def render(event:)
      <{ LayoutNode: }>
        <p class="lede">{"Every kind of event and what observes it."}</p>

        <div class="panel">
          <table>
            <thead>
              <tr>
                <th scope="col">Event</th>
                <th scope="col">Observers</th>
              </tr>
            </thead>
            <tbody>
              <{ for: observer_key in: @event_types }>
                <tr>
                  <td>{observer_key}</td>
                  <td>
                    <{ ObserversFormatter observer_key=observer_key }>
                  </td>
                </tr>
              <{ :for }>
            </tbody>
          </table>
        </div>
      <{ :LayoutNode }>
    end
  end
end
