# frozen_string_literal: true

require 'protocol/http'
require_relative '../../../lib/security/cross_origin_protection'

RSpec.describe Rain::CrossOriginProtection do
  def request(method: 'POST', **headers)
    headers = { 'host' => 'example.com', **headers.transform_keys { it.to_s.tr('_', '-') } }
    Protocol::HTTP::Request.new('https', 'example.com', method, '/cart', nil, Protocol::HTTP::Headers[headers], nil)
  end

  it "lets in what a browser says came from this site, or what's typed in or bookmarked" do
    expect([described_class.same_origin?(request(sec_fetch_site: 'same-origin')),
            described_class.same_origin?(request(sec_fetch_site: 'none'))]).to eq([true, true])
  end

  it 'turns away what a browser says came from another site, even one sharing the domain' do
    expect([described_class.same_origin?(request(sec_fetch_site: 'cross-site', origin: 'https://example.com')),
            described_class.same_origin?(request(sec_fetch_site: 'same-site'))]).to eq([false, false])
  end

  it "checks an older browser's Origin against the host" do
    expect([described_class.same_origin?(request(origin: 'https://example.com')),
            described_class.same_origin?(request(origin: 'https://evil.example')),
            described_class.same_origin?(request(origin: 'null')),
            described_class.same_origin?(request(origin: 'http://localhost:4133', host: 'localhost:4133'))])
      .to eq([true, false, false, true])
  end

  it "lets in what isn't from a browser, like a webhook, and what doesn't change anything, like GET" do
    expect([described_class.same_origin?(request),
            described_class.same_origin?(request(method: 'GET', sec_fetch_site: 'cross-site'))]).to eq([true, true])
  end

  def event(request)
    Struct.new(:request).new(request)
  end

  it "answers another site's request with the app's 403 page, or a plain one, and lets the rest through" do
    allow(Low::Events::StatusEvent).to receive(:take).and_return('403 page', nil)

    expect([described_class.request(event: event(request(sec_fetch_site: 'cross-site'))),
            described_class.request(event: event(request(sec_fetch_site: 'cross-site'))).response.status,
            described_class.request(event: event(request(sec_fetch_site: 'same-origin')))]).to eq(['403 page', 403, nil])
  end
end
