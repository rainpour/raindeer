# frozen_string_literal: true

require 'observers'
require 'lownode'
require 'dirload'
require 'antlers'
require_relative '../../../lib/raindeer/integrations'
require_relative '../../factories/request_factory'

%w[numbers traffic request_log memory_node stats].each do |name|
  dirload(File.join(Dir.pwd, "/lib/system/#{name}.rb"))
end

RSpec.describe System::Stats do
  subject(:stats) { described_class.new }

  before { allow(Providers).to receive(:[]).with('low.event.pool').and_return(Low::Events::EventPool.new) }

  it 'has 16 stats, four to a row, each with its own key' do
    expect([stats.all.size, stats.all.map(&:key).uniq.size, stats.all.first(4).map(&:title)])
      .to eq([16, 16, ['Uptime', 'Visitors (5 min)', 'Requests per second', 'Actions per second']])
  end

  it 'gives each value as text by its key, for the dashboard to refresh' do
    expect(stats.to_h.values.all?(String) && stats.to_h.keys).to eq(stats.all.map(&:key))
  end
end

RSpec.describe System::Traffic do
  before do
    described_class.instance_variable_set(:@seen, {})
    described_class.instance_variable_set(:@requests, Hash.new(0))
  end

  it "doesn't count the system pages, so the dashboard refreshing itself isn't traffic" do
    %w[/system /system/stats /threads].each do |path|
      request = Low::Support::RequestFactory.request(path:)
      request.headers.add('cf-connecting-ip', "203.0.113.#{path.size}")
      described_class.request(event: Low::Events::RequestEvent.new(request:))
    end
    expect([described_class.visitors, described_class.busiest_second]).to eq([1, 1])
  end
end
