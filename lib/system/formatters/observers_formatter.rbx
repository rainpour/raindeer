# frozen_string_literal: true

class ObserversFormatter < LowNode
  def initialize(event:, observer_key:)
    # TODO: What's the best way to do this? An "if:" at the template layer? A decorator at the node layer?
    if observer_key.to_s == 'Rain::Events::RouteEvent'
      routes_count = Providers['rain.router'].routes.count
      @observers = ["#{routes_count} routes"]
    else
      @observers = observer_key.observers.to_a.map { |observer| name(observer.object) }
    end
  end
    
  def render(event:, observer_key:)
    <ul>
      <{ for: observer in: @observers }>
        <li>{ observer }</li>
      <{ :for }>
    </ul>
  end

  private

  # A class by its name, and an object like a FileServer by its class's, rather than its address in memory.
  def name(object)
    return object.name if object.is_a?(Module)

    object.class.name
  end
end
