# frozen_string_literal: true

# What's inside a request's details: its summary line, then where its time went as a bar and every event it caused in
# the order they branched from the request.
class RequestFormatter < LowNode
  def render(event:, entry:) # rubocop:disable Lint/UnusedMethodArgument
    <summary>
      <code>{entry.verb}</code>{" "}<strong>{entry.path}</strong>
      <small>{" "}{entry.status}{" · "}{entry.milliseconds}{" ms · "}{entry.events}{" events · "}{entry.seconds_ago}{" s ago"}</small>
      <{ if: entry.referrer }>
        <small class="referrer">{"from "}{entry.referrer}</small>
      <{ :if }>
      <{ if: entry.visit_path }>
        <a class="visit" href="{entry.visit_path}" role="button">{"Visit"}</a>
      <{ :if }>
    </summary>
    <{ LifecycleFormatter root=entry.root }>
    <ul class="tree">
      <{ BranchFormatter branch=entry.root }>
    </ul>
  end
end
