# frozen_string_literal: true

# A class by its name as code with its namespace in Pico's tooltip like RequestEvent for Low::Events::RequestEvent.
class ClassNameFormatter < LowNode
  def initialize(event:, full_name:)
    @name = full_name.split('::').last
  end

  def render(event:, full_name:) # rubocop:disable Lint/UnusedMethodArgument
    <code data-tooltip="{full_name}">{@name}</code>
  end
end
