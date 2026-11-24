# frozen_string_literal: true

require 'dirload'

dirload(File.join(Dir.pwd, '/lib/system/lifecycle.rb'))

RSpec.describe System::Lifecycle do
  # Stand-ins for events with how long each took and the events it caused.
  let(:event) { Struct.new(:milliseconds, :children) }

  before do
    stub_const('RequestEvent', Class.new(event))
    stub_const('RouteEvent', Class.new(event))
    stub_const('NodeEvent', Class.new(event))
    stub_const('DataEvent', Class.new(event))
  end

  it "gives each kind of event its own time without its children's in the order they happen" do
    nodes = [NodeEvent.new(3, [DataEvent.new(2, [])]), NodeEvent.new(1, [])]
    request = RequestEvent.new(10, [RouteEvent.new(8, nodes)])

    expect(described_class.new(request).segments.map { |segment| [segment.name, segment.milliseconds] })
      .to eq([['Request', 2.0], ['Route', 4.0], ['Node', 2.0], ['Data', 2.0]])
  end

  it "has no segments for a request that's still being answered" do
    expect(described_class.new(RequestEvent.new(nil, [])).segments).to eq([])
  end

  it 'labels a segment with its time with a decimal under 10 ms' do
    segments = [3.14159, 42.4].map { |milliseconds| described_class::Segment.new(name: 'Route', milliseconds:) }

    expect(segments.map(&:label)).to eq(['Route 3.1 ms', 'Route 42 ms'])
  end
end
