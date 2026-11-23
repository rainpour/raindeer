# frozen_string_literal: true

# Numbers over time as a line that fills its box from the lowest to the highest, like memory each minute.
class TrendFormatter < LowNode
  WIDTH = 600
  HEIGHT = 80

  def initialize(event:, title:, values:)
    @title = title
    @points = line_points(values)
    @lowest = values.min
    @highest = values.max
  end

  def render(event:, title:, values:) # rubocop:disable Lint/UnusedMethodArgument
    <article class="trend">
      <svg viewBox="0 0 600 80" preserveAspectRatio="none" role="img" aria-label="{@title}">
        <polyline points="{@points}"></polyline>
      </svg>
      <footer>{@title}{": "}{@lowest}{" to "}{@highest}</footer>
    </article>
  end

  private

  # Each value's place on the line, spread evenly across and scaled so the lowest is at the bottom and the highest at the top.
  def line_points(values)
    range = [values.max - values.min, 1].max
    step = WIDTH.fdiv([values.size - 1, 1].max)
    values.each_with_index.map do |value, index|
      "#{(index * step).round(1)},#{(HEIGHT - 4 - ((value - values.min) * (HEIGHT - 8) / range.to_f)).round(1)}"
    end.join(' ')
  end
end
