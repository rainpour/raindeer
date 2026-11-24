# frozen_string_literal: true

class ObserversFormatter < LowNode
  def initialize(event:, observer_key:)
    @observers = observer_key.observers.to_a.map { |observer| name(observer.object) }.uniq
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
