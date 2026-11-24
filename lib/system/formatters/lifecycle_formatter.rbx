# frozen_string_literal: true

# A request's events as a bar with each kind of event a segment as wide as its own time. Its label shows when there's room
# and Pico's tooltip shows the whole label when there isn't.
class LifecycleFormatter < LowNode
  def initialize(event:, root:)
    @segments = System::Lifecycle.new(root).segments
    @timed = @segments.any?
  end

  def render(event:, root:) # rubocop:disable Lint/UnusedMethodArgument
    <{ if: @timed }>
      <div class="lifecycle">
        <{ for: segment in: @segments }>
          <span style="flex-grow: {segment.milliseconds}"><span class="tip" data-tooltip="{segment.label}"><span class="label">{segment.name}{" "}<small>{segment.duration}</small></span></span></span>
        <{ :for }>
      </div>
    <{ :if }>
  end
end
