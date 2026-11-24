# frozen_string_literal: true

module System
  # Where an average request spends its time by kind of event in the order they happen. Events wait for the events they
  # cause so each one's own time leaves out its children's.
  class Lifecycle
    # A kind of event and its own time in an average request.
    Segment = Data.define(:name, :milliseconds) do
      def label
        "#{name} #{duration}"
      end

      # Under 10 ms with a decimal as most events take less than one.
      def duration
        return "#{milliseconds.round(1)} ms" if milliseconds < 10

        "#{milliseconds.round} ms"
      end
    end

    attr_reader :segments

    def initialize(entries: RequestLog.new.entries)
      roots = entries.map(&:root).select(&:milliseconds)
      totals = Hash.new(0.0)
      roots.each { |root| add_own_times(root, totals) }
      @segments = totals.map { |name, total| Segment.new(name:, milliseconds: total / roots.size) }
    end

    private

    # Adds each event's time without its children's to its kind's total from the request down.
    def add_own_times(event, totals)
      children = event.children.dup
      own = event.milliseconds.to_f - children.sum { |child| child.milliseconds.to_f }
      totals[event.class.name.split('::').last.delete_suffix('Event')] += own.clamp(0, nil)
      children.each { |child| add_own_times(child, totals) }
    end
  end
end
