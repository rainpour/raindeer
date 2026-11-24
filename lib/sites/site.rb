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
    def self.from_request(request)
      headers = request.headers
      authority = Array(headers['host']).first || request.authority.to_s
      scheme = Array(headers['x-forwarded-proto']).first || request.scheme || 'http'
      at_host(authority.split(':').first.to_s.downcase, origin: "#{scheme}://#{authority}")
    end

    # The site at a host, with its settings from config.yaml.
    def self.at_host(host, origin:)
      settings = configured.fetch(host, {})
      new(host:, origin:, region: settings[:region]&.to_s&.upcase, language: settings[:language]&.to_s || Translations.source_locale)
    end

    # Each site set in config.yaml, by its host.
    def self.configured
      return {} unless Providers.providers.key?('rain.config')

      (Providers['rain.config'].sites || {}).to_h { |host, settings| [host.to_s.downcase, settings || {}] }
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
