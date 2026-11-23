# frozen_string_literal: true

require 'observers'
require 'lownode'
require 'dirload'
require 'antlers'
require_relative '../../../lib/raindeer/integrations'
require_relative '../../factories/request_factory'

dirload(File.join(Dir.pwd, '/lib/system/request_log.rb'))
dirload(File.join(Dir.pwd, '/lib/system/visitor_address.rb'))
dirload(File.join(Dir.pwd, '/lib/system/traffic.rb'))
dirload(File.join(Dir.pwd, '/lib/system/numbers.rb'))
dirload(File.join(Dir.pwd, '/lib/system/formatters/intervals_formatter.rbx'))

RSpec.describe System::RequestLog do
  # A request's tree of a request event and its response, made at a time in milliseconds and taking how long it took.
  # Optionally the status it answered, the address it came from, its verb and whether it's still being answered.
  def tree(path, at:, took:, **options)
    http = Low::Support::RequestFactory.request(path:, verb: options.fetch(:verb, 'GET'))
    http.headers.add('cf-connecting-ip', options[:from]) if options[:from]
    request = Low::Events::RequestEvent.new(request: http)
    response = Low::Events::ResponseEvent.new(response: Protocol::HTTP::Response[options.fetch(:status, 200)])
    request.instance_variable_set(:@created_at, at)
    response.instance_variable_set(:@created_at, at + took)
    events = [request]
    events << response if options.fetch(:answered, true)
    Low::Events::EventTree.new(request_id: path).tap { |each_tree| events.each { each_tree.branch(event: it) } }
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

  it 'gives the middle and the slowest response time' do
    expect([log.typical_milliseconds, log.slowest_milliseconds]).to eq([30, 80])
  end

  it 'counts the requests still being answered' do
    trees = { a: tree('/a', at: 199_000, took: 1), b: tree('/b', at: 199_500, took: 1, answered: false) }
    expect(described_class.new(event_trees: trees, now:).answering).to eq(1)
  end

  it "links a GET to visit again but not a form's POST" do
    trees = { a: tree('/shop', at: 199_000, took: 1), b: tree('/invite', at: 199_500, took: 1, verb: 'POST') }
    expect(described_class.new(event_trees: trees, now:).entries.map(&:visit_path)).to eq([nil, '/shop'])
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

RSpec.describe System::Traffic do
  before do
    described_class.instance_variable_set(:@seen, {})
    described_class.instance_variable_set(:@requests, Hash.new(0))
    described_class.instance_variable_set(:@forgot_at, nil)
  end

  it 'counts each different address in the last 5 minutes, however many requests there are' do
    150.times { |index| described_class.record("203.0.113.#{index % 120}", now: 1000.0) }
    described_class.record('198.51.100.2', now: 1000.0)
    expect(described_class.visitors(now: 1001.0)).to eq(121)
  end

  it 'forgets a visitor 5 minutes after it was last seen' do
    described_class.record('203.0.113.7', now: 1000.0)
    described_class.record('198.51.100.2', now: 1200.0)
    expect([described_class.visitors(now: 1250.0), described_class.visitors(now: 1350.0)]).to eq([2, 1])
  end

  it 'counts every request in the last minute, past the event pool\'s 100' do
    250.times { |index| described_class.record(nil, now: 1000.0 + (index * 0.1)) }
    expect([described_class.per_minute(now: 1030.0), described_class.per_minute(now: 1090.0)]).to eq([250, 0])
  end

  it "doesn't keep anyone's address, only a hash of it" do
    described_class.record('203.0.113.7', now: 1000.0)
    expect(described_class.instance_variable_get(:@seen).keys.first).not_to include('203.0.113.7')
  end

  it 'passes each request on so the next observer answers it' do
    request = Low::Support::RequestFactory.request(path: '/')
    request.headers.add('cf-connecting-ip', '203.0.113.7')
    expect([described_class.request(event: Low::Events::RequestEvent.new(request:)), described_class.visitors]).to eq([nil, 1])
  end
end

RSpec.describe System::VisitorAddress do
  def headers(pairs)
    Protocol::HTTP::Headers.new.tap { |list| pairs.each { |name, value| list.add(name, value) } }
  end

  it "takes Cloudflare's address first, then the visitor's from x-forwarded-for" do
    expect([described_class.from(headers('cf-connecting-ip' => '203.0.113.7', 'x-forwarded-for' => '10.0.0.1')),
            described_class.from(headers('x-forwarded-for' => '198.51.100.2, 10.0.0.1')),
            described_class.from(headers('accept' => 'text/html'))]).to eq(['203.0.113.7', '198.51.100.2', nil])
  end
end
