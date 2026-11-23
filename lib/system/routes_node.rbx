# frozen_string_literal: true

module System
  class RoutesNode < LowNode
    observe '/system/routes'

    def initialize(event:)
      @routes = Providers['rain.router'].routes
    end

    def render(event:)
      <{ LayoutNode: }>
        <p class="lede">{"Every route and what observes it."}</p>

        <div class="panel">
          <table>
            <thead>
              <tr>
                <th scope="col">HTTP Verbs</th>
                <th scope="col">Route</th>
                <th scope="col">Observers</th>
              </tr>
            </thead>
            <tbody>
              <{ for: path, route in: @routes }>
                <tr>
                  <td><{ LabelFormatter labels=route.verbs }></td>
                  <td>{route.path}</td>
                  <td><{ ObserversFormatter observer_key=route.path }></td>
                </tr>
              <{ :for }>
            </tbody>
          </table>
        </div>
      <{ :LayoutNode }>
    end
  end
end
