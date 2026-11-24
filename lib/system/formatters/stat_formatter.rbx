# frozen_string_literal: true

# A number with what it counts, which links to where it came from with an href. Its key lets the dashboard refresh the
# number each second.
class StatFormatter < LowNode
  def initialize(title:, stat:, key:, href: '')
    @title = title
    @stat = stat
    @key = key
    @href = href
    @linked = !href.empty?
    @unlinked = href.empty?
  end

  def render
    <article class="stat">
      <div class="number" data-stat="{@key}">{@stat}</div>
      <{ if: @linked }><footer><a href="{@href}">{@title}</a></footer><{ :if }>
      <{ if: @unlinked }><footer>{@title}</footer><{ :if }>
    </article>
  end
end
