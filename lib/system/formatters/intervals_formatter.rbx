# frozen_string_literal: true

# Each interval the app observes on dials of the seconds and minutes and hours on every mark its turns start. A neon
# line steps down each dial with the server's clock so you can see when its jobs run.
class IntervalsFormatter < LowNode
  Schedule = Data.define(:interval, :observers, :tip)
  Mark = Data.define(:number, :schedules)

  UNITS = { 'day' => 86_400, 'hour' => 3600, 'minute' => 60, 'second' => 1 }.freeze

  # The seconds in this minute or the minutes in this hour or the hours in this day with what starts a turn on each.
  class Dial
    attr_reader :unit, :marks

    def initialize(unit:, size:, step:, schedules:, now:)
      @unit = unit
      @step = step
      start = now - ((now.to_i + now.utc_offset) % (size * step))
      held = schedules.select { |schedule| holds?(schedule.interval) }
      @marks = Array.new(size) do |number|
        time = start + (number * step)
        Mark.new(number:, schedules: held.select { |schedule| runs_at?(schedule.interval, time) })
      end
    end

    private

    # An interval is on the dial of the largest unit it runs in whole numbers of. A day's is on the hours dial.
    def holds?(interval)
      return false unless (interval.seconds % @step).zero?
      return true if unit == 'hours'

      !(interval.seconds % (@step * 60)).zero?
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
    @dials = [Dial.new(unit: 'seconds', size: 60, step: 1, schedules:, now:),
              Dial.new(unit: 'minutes', size: 60, step: 60, schedules:, now:),
              Dial.new(unit: 'hours', size: 24, step: 3600, schedules:, now:)]
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
                  <span class="mark">{mark.number}</span>
                  <{ for: schedule in: mark.schedules }>
                    <span class="observer" data-tooltip="{schedule.tip}">{schedule.observers}</span>
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
