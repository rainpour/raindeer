# frozen_string_literal: true

module System
  class EventsNode < LowNode
    observe '/system/events'

    # An event class and the routes to link to instead of listing what observes them when it's the route event.
    Row = Data.define(:event_class, :routes) do
      def name
        event_class.name
      end

      def listed?
        routes.nil?
      end
    end

    def initialize(event:)
      # TODO: Include types that can be observed keys too like Status and Status[404].
      routes = Providers['rain.router'].routes.size
      @rows = LowEvent.events.map do |event_class|
        Row.new(event_class:, routes: (routes if event_class == Rain::Events::RouteEvent))
      end
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
              <{ for: row in: @rows }>
                <tr>
                  <td><{ ClassNameFormatter full_name=row.name }></td>
                  <td>
                    <{ if: row.routes }>
                      <a href="/system/routes">{row.routes}{" routes"}</a>
                    <{ :if }>
                    <{ if: row.listed? }>
                      <{ ObserversFormatter observer_key=row.event_class }>
                    <{ :if }>
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
