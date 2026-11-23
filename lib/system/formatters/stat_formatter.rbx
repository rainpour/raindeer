# frozen_string_literal: true

# A number with what it counts. Its key lets the dashboard refresh the number each second.
class StatFormatter < LowNode
  def render(event:, title:, stat:, key:)
    <article class="stat">
      <div class="number" data-stat="{key}">{stat}</div>
      <footer>{title}</footer>
    </article>
  end
end
