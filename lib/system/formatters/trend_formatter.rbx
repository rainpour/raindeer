# frozen_string_literal: true

# Numbers over time as a line with the area under it filled, from the lowest to the highest, like memory each minute.
class TrendFormatter < LowNode
  WIDTH = 600
  HEIGHT = 80

  def initialize(event:, title:, values:)
    @title = title
    @points = line_points(values)
    # The line closed along the bottom of the chart, so the area under it can be filled.
    @area = "0,#{HEIGHT} #{@points} #{WIDTH},#{HEIGHT}"
    @lowest = System::Numbers.delimited(values.min)
    @highest = System::Numbers.delimited(values.max)
  end

  def render(event:, title:, values:) # rubocop:disable Lint/UnusedMethodArgument
    <article class="trend">
      <svg viewBox="0 0 600 80" preserveAspectRatio="none" role="img" aria-label="{@title}">
        <polygon points="{@area}"></polygon>
        <polyline points="{@points}"></polyline>
      </svg>
      <footer>{@title}{": "}{@lowest}{" to "}{@highest}</footer>
    </article>
  end

  private

  # Each value's place on the line, spread evenly across and scaled so the lowest is at the bottom and the highest at the top.
  def line_points(values)
    # A lone value is drawn across the whole chart until there's a second.
    values *= 2 if values.one?
    lowest = values.min
    range = values.max - lowest
    # A line that never changes runs across the middle, so it reads as steady rather than empty.
    lowest, range = lowest - 1, 2 if range.zero?
    step = WIDTH.fdiv([values.size - 1, 1].max)
    values.each_with_index.map do |value, index|
      "#{(index * step).round(1)},#{(HEIGHT - 4 - ((value - lowest) * (HEIGHT - 8) / range.to_f)).round(1)}"
    end.join(' ')
  end
end
