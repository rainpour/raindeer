# frozen_string_literal: true

require 'ostruct'
require 'protocol/http'
require 'antlers'
require_relative '../../../lib/translations/translations'
require_relative '../../../lib/router/events/route_event'
require_relative '../../../lib/router/route'

RSpec.describe Rain::Site do
  # A request to a host, with any other headers, like a proxy's or Cloudflare's.
  def request(host, **headers)
    fields = Protocol::HTTP::Headers.new
    fields.add('host', host)
    headers.each { |name, value| fields.add(name.to_s.tr('_', '-'), value) }
    Protocol::HTTP::Request.new('http', host, 'GET', '/', nil, fields, nil)
  end

  before do
    sites = { 'sourdough.com.au': { region: 'au' }, 'sourdough.com': nil, 'levain.fr': { region: 'FR', language: 'fr' } }
    allow(Providers).to receive(:providers).and_return({ 'rain.config' => true })
    allow(Providers).to receive(:[]).with('rain.config').and_return(OpenStruct.new(sites:))
  end

  it 'is the site set for the host a request came to, with the scheme the proxy forwarded it with' do
    site = described_class.from_request(request('sourdough.com.au', x_forwarded_proto: 'https'))

    expect([site.host, site.origin, site.region, site.language]).to eq(['sourdough.com.au', 'https://sourdough.com.au', 'AU', 'en'])
  end

  it "is a site without a region for a host that isn't set, keeping its port in its origin" do
    site = described_class.from_request(request('localhost:4133'))

    expect([site.host, site.origin, site.region]).to eq(['localhost', 'http://localhost:4133', nil])
  end

  it 'names itself for hreflang links, with x-default for the site for everyone else' do
    expect(described_class.from_request(request('levain.fr')).alternates.map { |site| [site.hreflang, site.origin] })
      .to eq([%w[en-au http://sourdough.com.au], %w[x-default http://sourdough.com], %w[fr-fr http://levain.fr]])
  end

  describe Rain::Locale do
    it "takes the site's region and the visitor's language when there's a translation for it" do
      allow(Antlers::Translations).to receive(:locales).and_return(['en-US'])
      locale = described_class.from_request(request('sourdough.com.au', accept_language: 'en-US,en;q=0.8'), site: Rain::Site.from_request(request('sourdough.com.au')))

      expect([locale.language, locale.region]).to eq(%w[en-US AU])
    end

    it "takes the site's language without a translation for the visitor's" do
      allow(Antlers::Translations).to receive(:locales).and_return([])
      site = Rain::Site.from_request(request('levain.fr'))

      expect(described_class.from_request(request('levain.fr', accept_language: 'de'), site:).language).to eq('fr')
    end

    it "takes the country Cloudflare found the visitor in on a site without a region, but not one it couldn't place" do
      site = Rain::Site.from_request(request('sourdough.com'))

      regions = %w[US XX T1].map { |code| described_class.from_request(request('sourdough.com', cf_ipcountry: code), site:).region }

      expect(regions).to eq(['US', nil, nil])
    end
  end

  it "gives a route event its request's site and locale" do
    event = Rain::Events::RouteEvent.new(route: Rain::Route.new(path: '/'), request: request('sourdough.com.au'))

    expect([event.site.host, event.locale.region]).to eq(%w[sourdough.com.au AU])
  end
end
