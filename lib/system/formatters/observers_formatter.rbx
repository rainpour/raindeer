# frozen_string_literal: true

# What observes a key by name. The Events page gives an event class and the Routes page a route's path.
class ObserversFormatter < LowNode
  def initialize(event:, observer_key:)
    @observers = observers_of(observer_key).map { |observer| name(observer.object) }.uniq
  end

  def render(event:, observer_key:)
    <ul>
      <{ for: observer in: @observers }>
        <li><{ ClassNameFormatter full_name=observer }></li>
      <{ :for }>
    </ul>
  end

  private

  # An event class answers for itself as nodes observe other keys like a route's path. Any other key is looked up.
  def observers_of(key)
    return key.observers.to_a if key.respond_to?(:observers)

    Observers::Keys.find(key)&.observers || []
  end

  # A class by its name, and an object like a FileServer by its class's, rather than its address in memory.
  def name(object)
    return object.name if object.is_a?(Module)

    object.class.name
  end
end
