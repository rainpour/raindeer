# frozen_string_literal: true

# Each interval the app observes on dials of seconds and minutes and hours and days on every mark its turns start. A neon
# line steps down each dial with the server's clock so you can see when its jobs run.
class IntervalsFormatter < LowNode
  Schedule = Data.define(:interval, :observers, :tip)
  Mark = Data.define(:label, :schedules)

  UNITS = { 'day' => 86_400, 'hour' => 3600, 'minute' => 60, 'second' => 1 }.freeze
  WEEKDAYS = %w[Mon Tue Wed Thu Fri Sat Sun].freeze
  # The epoch began on a Thursday so weeks start 4 days after it on a Monday.
  MONDAY = 4 * 86_400

  # The seconds in this minute or minutes in this hour or hours in this day or days in this week with what starts a turn
  # on each.
  class Dial
    attr_reader :unit, :marks

    def initialize(unit:, step:, labels:, schedules:, now:, origin: 0)
      @unit = unit
      @step = step
      @span = labels.size * step
      start = now - ((now.to_i + now.utc_offset - origin) % @span)
      held = schedules.select { |schedule| holds?(schedule.interval) }
      @marks = labels.each_with_index.map do |label, index|
        time = start + (index * step)
        Mark.new(label:, schedules: held.select { |schedule| runs_at?(schedule.interval, time) })
      end
    end

    private

    # An interval is on the dial of the largest unit it's more than one of. So a daily job is on the hours dial.
    def holds?(interval)
      largest = UNITS.values.find { |size| (interval.seconds % size).zero? && interval.seconds > size } || 1
      largest == @step
    end

    # One kept to an hour runs once in it on the hours dial.
    def runs_at?(interval, time)
      return time.hour == interval.at_hour if interval.at_hour && unit == 'hours'

      interval.starts_turn?(time)
    end
  end

  def initialize(event:)
    now = Time.now
    schedules = Observers::Keys.keys.keys.grep(Low::Loop::Interval).map do |interval|
      Schedule.new(interval:, observers: Observers[interval].map { |observer| observer.object.to_s }.join(', '),
                   tip: "#{every(interval)} · #{ticked(interval.triggered_at)}")
    end
    @dials = [Dial.new(unit: 'seconds', step: 1, labels: (0..59).to_a, schedules:, now:),
              Dial.new(unit: 'minutes', step: 60, labels: (0..59).to_a, schedules:, now:),
              Dial.new(unit: 'hours', step: 3600, labels: (0..23).to_a, schedules:, now:),
              Dial.new(unit: 'days', step: 86_400, labels: WEEKDAYS, schedules:, now:, origin: MONDAY)]
    @any = schedules.any?
    @offset = now.utc_offset
  end

  def render(event:) # rubocop:disable Lint/UnusedMethodArgument
    <{ if: @any }>
      <div class="dials" data-offset="{@offset}">
        <{ for: dial in: @dials }>
          <article class="dial" data-unit="{dial.unit}">
            <header>{dial.unit}</header>
            <ol style="--slots: {dial.marks.size}">
              <{ for: mark in: dial.marks }>
                <li>
                  <span class="mark">{mark.label}</span>
                  <{ for: schedule in: mark.schedules }>
                    <span class="observer" data-tooltip="{schedule.tip}"><span>{schedule.observers}</span></span>
                  <{ :for }>
                </li>
              <{ :for }>
            </ol>
          </article>
        <{ :for }>
      </div>
    <{ :if }>
  end

  private

  # How often it runs in its largest whole unit like "Every 3 minutes" or "Every day at hour 2".
  def every(interval)
    name, size = UNITS.find { |_, unit| (interval.seconds % unit).zero? }
    count = interval.seconds / size
    text = "Every #{name}"
    text = "Every #{count} #{name}s" unless count == 1
    return text unless interval.at_hour

    "#{text} at hour #{interval.at_hour}"
  end

  def ticked(at)
    return 'Not run yet' unless at

    "Ran #{(Time.now - at).round} s ago"
  end
end
