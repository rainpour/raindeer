# frozen_string_literal: true

require 'ostruct'
require 'protocol/http'
require_relative '../../../lib/security/rate_limit'

RSpec.describe Rain::RateLimit do
  def request(path, address: '203.0.113.1')
    headers = Protocol::HTTP::Headers[{ 'cf-connecting-ip' => address }]
    Low::Events::RequestEvent.new(request: Protocol::HTTP::Request.new('https', 'example.com', 'GET', path, nil, headers, nil))
  end

  before do
    described_class.instance_variable_set(:@counts, {})
    described_class.instance_variable_set(:@denied, Hash.new(0))
    described_class.instance_variable_set(:@denied_trees, [])
    allow(Providers).to receive(:[]).and_call_original
    allow(Providers).to receive(:[]).with('rain.config').and_return(OpenStruct.new(rate_limits: { '/': 3, '/search': 2 }))
    allow(Low::Events::StatusEvent).to receive(:take).and_return(nil)
  end

  it 'turns a visitor away with when to try again once they pass the limit' do
    responses = Array.new(3) { described_class.request(event: request('/search?q=rye')) }
    expect([responses.first(2), responses.last.response.status, responses.last.response.headers['retry-after'].to_i.between?(1, 60)])
      .to eq([[nil, nil], 429, true])
  end

  it 'counts the paths under a limited path with it, but not others or other visitors' do
    2.times { described_class.request(event: request('/search')) }
    expect([described_class.request(event: request('/search/more')).nil?, described_class.request(event: request('/searching')),
            described_class.request(event: request('/search', address: '203.0.113.2'))]).to eq([false, nil, nil])
  end

  it 'gives a path the most specific limit, so / covers every page apart from those with their own' do
    pages = Array.new(4) { |page| described_class.request(event: request("/posts/#{page}")) }
    searches = Array.new(3) { described_class.request(event: request('/search')) }
    expect([pages.map(&:nil?), searches.map(&:nil?)]).to eq([[true, true, true, false], [true, true, false]])
  end

  it "doesn't count the system pages, as the dashboard refreshes itself each second" do
    expect(Array.new(5) { described_class.request(event: request('/system/stats')) }.uniq).to eq([nil])
  end

  it "doesn't limit a request without an address, like while developing" do
    unknown = Low::Events::RequestEvent.new(request: Protocol::HTTP::Request.new('https', 'example.com', 'GET', '/search', nil,
                                                                                 Protocol::HTTP::Headers.new, nil))
    expect(Array.new(3) { described_class.request(event: unknown) }).to eq([nil, nil, nil])
  end

  it 'counts the requests denied in the last 24 hours' do
    3.times { described_class.wait_for('a /search', limit: 1, now: 100) }
    expect([described_class.denied(now: 86_000), described_class.denied(now: 86_500)]).to eq([2, 0])
  end

  it 'counts afresh each minute' do
    expect([described_class.wait_for('a /search', limit: 1, now: 90), described_class.wait_for('a /search', limit: 1, now: 95),
            described_class.wait_for('a /search', limit: 1, now: 121)]).to eq([nil, 25, nil])
  end

  it "keeps the last 100 denied requests' trees for the requests page once the pool has moved on" do
    pool = double.as_null_object
    allow(Providers).to receive(:[]).with('low.event.pool').and_return(pool)
    allow(pool).to receive(:event_tree_now) { Object.new }
    2.times { described_class.request(event: request('/search')) }
    allowed = described_class.denied_trees.size
    102.times { described_class.request(event: request('/search')) }
    expect([allowed, described_class.denied_trees.size]).to eq([0, 100])
  end
end
