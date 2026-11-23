# frozen_string_literal: true

require 'observers'
require 'lownode'
require 'dirload'
require 'antlers'
require_relative '../../../lib/raindeer/integrations'
require_relative '../../factories/request_factory'

dirload(File.join(Dir.pwd, '/lib/system/request_log.rb'))
dirload(File.join(Dir.pwd, '/lib/system/numbers.rb'))
dirload(File.join(Dir.pwd, '/lib/system/formatters/intervals_formatter.rbx'))

RSpec.describe System::RequestLog do
  # A request's tree of a request event and its response, made at a time in milliseconds and taking how long it took.
  def tree(path, at:, took:, status: 200)
    request = Low::Events::RequestEvent.new(request: Low::Support::RequestFactory.request(path:))
    response = Low::Events::ResponseEvent.new(response: Protocol::HTTP::Response[status])
    request.instance_variable_set(:@created_at, at)
    response.instance_variable_set(:@created_at, at + took)
    Low::Events::EventTree.new(request_id: path).tap { |each_tree| [request, response].each { each_tree.branch(event: it) } }
  end

  let(:now) { 200_000 }
  let(:trees) do
    { a: tree('/old', at: 100_000, took: 30), b: tree('/new', at: 190_000, took: 10, status: 404),
      c: tree('/newer', at: 199_000, took: 80) }
  end
  let(:log) { described_class.new(event_trees: trees, now:) }

  it 'lists each request newest first with what it answered and how long it took' do
    entry = log.entries.first
    expect([log.entries.map(&:path), entry.verb, entry.status, entry.events, entry.milliseconds, entry.seconds_ago])
      .to eq([%w[/newer /new /old], 'GET', 200, 2, 80, 1])
  end

  it 'counts the requests in the last minute' do
    expect(log.per_minute).to eq(2)
  end

  it 'gives the middle and the slowest response time' do
    expect([log.typical_milliseconds, log.slowest_milliseconds]).to eq([30, 80])
  end

  it 'leaves out trees an interval started' do
    interval_tree = Low::Events::EventTree.new(request_id: 'tick').tap { it.branch(event: Low::Loop::Interval[every_second: 1]) }
    expect(described_class.new(event_trees: { tick: interval_tree }, now:).entries).to eq([])
  end
end

RSpec.describe IntervalsFormatter do
  def every(**schedule)
    described_class.allocate.send(:every, Low::Loop::Interval[**schedule])
  end

  it 'says how often an interval runs in its largest whole unit' do
    expect([every(every_second: 1), every(every_second: 90), every(every_minute: 3), every(every_hour: 1),
            every(every_minute: 3, at_hour: 2)])
      .to eq(['Every second', 'Every 90 seconds', 'Every 3 minutes', 'Every hour', 'Every 3 minutes at hour 2'])
  end
end

RSpec.describe System::Numbers do
  it 'puts commas between thousands' do
    expect([7, 1234, 591_812, 1_234_567].map { described_class.delimited(it) }).to eq(%w[7 1,234 591,812 1,234,567])
  end
end
