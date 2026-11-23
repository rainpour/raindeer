# frozen_string_literal: true

# Each interval the app observes, with how often it runs, what observes it and when it last ran, so you can see that
# its jobs are running.
class IntervalsFormatter < LowNode
  Schedule = Data.define(:every, :observers, :ticked)

  UNITS = { 'day' => 86_400, 'hour' => 3600, 'minute' => 60, 'second' => 1 }.freeze

  def initialize(event:)
    @schedules = Observers::Keys.keys.keys.grep(Low::Loop::Interval).map do |interval|
      Schedule.new(every: every(interval), observers: Observers[interval].map { |observer| observer.object.to_s }.join(', '),
                   ticked: ticked(interval.triggered_at))
    end
    @any = @schedules.any?
  end

  def render(event:) # rubocop:disable Lint/UnusedMethodArgument
    <{ if: @any }>
      <table>
        <thead>
          <tr>
            <th scope="col">{"Interval"}</th>
            <th scope="col">{"Observers"}</th>
            <th scope="col">{"Last ran"}</th>
          </tr>
        </thead>
        <tbody>
          <{ for: schedule in: @schedules }>
            <tr>
              <td>{schedule.every}</td>
              <td>{schedule.observers}</td>
              <td>{schedule.ticked}</td>
            </tr>
          <{ :for }>
        </tbody>
      </table>
    <{ :if }>
  end

  private

  # How often it runs in its largest whole unit, like "Every 3 minutes" or "Every day at hour 2".
  def every(interval)
    name, size = UNITS.find { |_, unit| (interval.seconds % unit).zero? }
    count = interval.seconds / size
    text = "Every #{name}"
    text = "Every #{count} #{name}s" unless count == 1
    return text unless interval.at_hour

    "#{text} at hour #{interval.at_hour}"
  end

  def ticked(at)
    return 'Not yet' unless at

    "#{(Time.now - at).round} s ago"
  end
end
