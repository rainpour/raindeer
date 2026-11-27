# frozen_string_literal: true

require 'providers'

module Rain
  # A site the app serves, by the host a request came to, like sourdough.com.au: its origin to link back to, the region
  # its visitors are most likely in, and the language its pages are written in. Hosts are set under "sites" in
  # config.yaml, and a host that isn't there is a site of its own without a region:
  #
  #   sites:
  #     sourdough.com.au: { region: AU }
  #     sourdough.com: {}
  Site = Data.define(:host, :origin, :region, :language) do
    # The site a request came to, by its Host header and the scheme a proxy like Caddy forwarded it with.
    # The last request's site is kept, as most requests come to the same one, so it isn't made again, unless the sites
    # in config.yaml have changed since.
    def self.from_request(request)
      headers = request.headers
      authority = Array(headers['host']).first || request.authority.to_s
      scheme = Array(headers['x-forwarded-proto']).first || request.scheme || 'http'

      sites = configured
      last_authority, last_scheme, last_sites, last_site = @last
      return last_site if last_authority == authority && last_scheme == scheme && last_sites.equal?(sites)

      site = at_host(authority.split(':').first.to_s.downcase, origin: "#{scheme}://#{authority}")
      @last = [authority, scheme, sites, site].freeze
      site
    end

    # The site at a host, with its settings from config.yaml.
    def self.at_host(host, origin:)
      settings = configured[host] || {}
      new(host:, origin:, region: settings[:region]&.to_s&.upcase, language: settings[:language]&.to_s || Translations.source_locale)
    end

    # Each site set in config.yaml, by its host. Read again only when the config's sites change.
    def self.configured
      return {} unless Providers.providers.key?('rain.config')

      sites = Providers['rain.config'].sites
      configured_from, configured = @configured
      return configured if configured && configured_from.equal?(sites)

      configured = (sites || {}).to_h { |host, settings| [host.to_s.downcase, settings || {}] }.freeze
      @configured = [sites, configured].freeze
      configured
    end

    # Its name in an hreflang link, like en-au, or x-default for a site without a region, which is for everyone else.
    def hreflang
      return 'x-default' unless region

      "#{language.split('-').first}-#{region.downcase}"
    end

    # The same page on each site set in config.yaml, including this one, for <link rel="alternate" hreflang> tags.
    def alternates
      scheme = origin.split('://').first
      self.class.configured.keys.map { |host| self.class.at_host(host, origin: "#{scheme}://#{host}") }
    end
  end
end
