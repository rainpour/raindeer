# frozen_string_literal: true

# An event in a request's tree with the action it called and its key, and under it the events it caused, so the whole
# tree can be read from the request down.
class BranchFormatter < LowNode
  def initialize(event:, branch:)
    @name = branch.class.name.split('::').last
    @action = branch.action || branch.actions.join(', ')
    # The key when it says more than the event's class, like a route's path.
    @key = branch.key.to_s unless [branch.class, branch].include?(branch.key)
    @children = branch.children.dup
    @parent = @children.any?
  end

  def render(event:, branch:) # rubocop:disable Lint/UnusedMethodArgument
    <li>
      <strong>{@name}</strong>{" "}<code>{@action}</code>
      <{ if: @key }>{" "}<small>{@key}</small><{ :if }>
      <{ if: @parent }>
        <ul>
          <{ for: child in: @children }>
            <{ BranchFormatter branch=child }>
          <{ :for }>
        </ul>
      <{ :if }>
    </li>
  end
end
