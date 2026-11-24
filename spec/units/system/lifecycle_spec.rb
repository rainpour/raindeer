# frozen_string_literal: true

require 'dirload'

%w[request_log lifecycle].each { |name| dirload(File.join(Dir.pwd, "/lib/system/#{name}.rb")) }

RSpec.describe System::Lifecycle do
  # Stand-ins for events with how long each took and the events it caused.
  let(:event) { Struct.new(:milliseconds, :children) }
  let(:entry) { Struct.new(:root) }

  before do
    stub_const('RequestEvent', Class.new(event))
    stub_const('RouteEvent', Class.new(event))
    stub_const('RenderEvent', Class.new(event))
  end

  def request(milliseconds, route:, render:)
    entry.new(RequestEvent.new(milliseconds, [RouteEvent.new(route, [RenderEvent.new(render, [])])]))
  end

  it "gives each kind of event its own time without its children's averaged across requests in the order they happen" do
    lifecycle = described_class.new(entries: [request(10, route: 8, render: 5), request(20, route: 12, render: 3)])

    expect(lifecycle.segments.map { |segment| [segment.name, segment.milliseconds] })
      .to eq([['Request', 5.0], ['Route', 6.0], ['Render', 4.0]])
  end

  it "leaves out a request that's still being answered" do
    still_answering = entry.new(RequestEvent.new(nil, []))

    expect(described_class.new(entries: [still_answering]).segments).to eq([])
  end

  it 'labels a segment with its time with a decimal under 10 ms' do
    segments = [3.14159, 42.4].map { |milliseconds| described_class::Segment.new(name: 'Route', milliseconds:) }

    expect(segments.map(&:label)).to eq(['Route 3.1 ms', 'Route 42 ms'])
  end
end
