# frozen_string_literal: true

# Each interval the app observes on dials of seconds and minutes and hours and days on every mark its turns start. A neon
# line steps down each dial with the server's clock and each mark's pill shows how its turn went.
class IntervalsFormatter < LowNode
  Schedule = Data.define(:interval, :observers, :every, :index)
  # A schedule on one mark with how its turn there went.
  Pill = Data.define(:key, :observers, :status, :tip)
  Mark = Data.define(:label, :pills)

  UNITS = { 'day' => 86_400, 'hour' => 3600, 'minute' => 60, 'second' => 1 }.freeze
  WEEKDAYS = %w[Mon Tue Wed Thu Fri Sat Sun].freeze
  # The epoch began on a Thursday so weeks start 4 days after it on a Monday.
  MONDAY = 4 * 86_400
  OUTCOMES = { running: 'Running', ran: 'Ran', failed: 'Failed', skipped: 'Skipped', nil => 'Not run' }.freeze

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
        pills = held.select { |schedule| runs_at?(schedule.interval, time) }.map { |schedule| pill_of(schedule, label, time, now) }
        Mark.new(label:, pills:)
      end
    end

    private

    def pill_of(schedule, label, time, now)
      outcome = schedule.interval.outcome_at(time, now:)
      Pill.new(key: "#{unit}-#{label}-#{schedule.index}", observers: schedule.observers, status: outcome.to_s,
               tip: "#{schedule.every} · #{OUTCOMES[outcome]}")
    end

    # An interval is on the dial of the largest unit it's more than one of. So a daily job is on the hours dial. One kept
    # to an hour only runs in it so it's on the hours dial at least.
    def holds?(interval)
      largest = UNITS.values.find { |size| (interval.seconds % size).zero? && interval.seconds > size } || 1
      largest = [largest, UNITS['hour']].max if interval.at_hour
      largest == @step
    end

    # One kept to an hour is on its hour on the hours dial.
    def runs_at?(interval, time)
      return time.hour == interval.at_hour if interval.at_hour && unit == 'hours'

      interval.starts_turn?(time)
    end
  end

  # Every dial now or none when nothing observes an interval.
  def self.dials(now)
    intervals = Observers::Keys.keys.keys.grep(Low::Loop::Interval)
    schedules = intervals.each_with_index.map do |interval, index|
      Schedule.new(interval:, observers: Observers[interval].map { |observer| observer.object.to_s }.join(', '),
                   every: every(interval), index:)
    end
    return [] if schedules.empty?

    [Dial.new(unit: 'seconds', step: 1, labels: (0..59).to_a, schedules:, now:),
     Dial.new(unit: 'minutes', step: 60, labels: (0..59).to_a, schedules:, now:),
     Dial.new(unit: 'hours', step: 3600, labels: (0..23).to_a, schedules:, now:),
     Dial.new(unit: 'days', step: 86_400, labels: WEEKDAYS, schedules:, now:, origin: MONDAY)]
  end

  # Each pill's outcome and tooltip by its key, which /system/stats sends so the dashboard can refresh them each second.
  def self.outcomes(now = Time.now)
    dials(now).flat_map(&:marks).flat_map(&:pills).to_h { |pill| [pill.key, { status: pill.status, tip: pill.tip }] }
  end

  # How often it runs in its largest whole unit like "Every 3 minutes" or "Every day at hour 2".
  def self.every(interval)
    name, size = UNITS.find { |_, unit| (interval.seconds % unit).zero? }
    count = interval.seconds / size
    text = "Every #{name}"
    text = "Every #{count} #{name}s" unless count == 1
    return text unless interval.at_hour

    "#{text} at hour #{interval.at_hour}"
  end

  def initialize(event:)
    now = Time.now
    @dials = self.class.dials(now)
    @any = @dials.any?
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
                  <{ for: pill in: mark.pills }>
                    <span class="observer" data-pill="{pill.key}" data-status="{pill.status}" data-tooltip="{pill.tip}"><span class="name">{pill.observers}</span><span class="spinner"></span></span>
                  <{ :for }>
                </li>
              <{ :for }>
            </ol>
          </article>
        <{ :for }>
      </div>
    <{ :if }>
  end

end
