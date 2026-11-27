# frozen_string_literal: true

require_relative 'request_header'

module Rain
  # Who a response is for: the language it's written in and the region its visitor is in, which can differ, like an
  # American reading the Australian site. The language is the visitor's Accept-Language among the translations there
  # are, or else the site's own. The region is the site's, or else the country a CDN like Cloudflare found them in.
  Locale = Data.define(:language, :region) do
    def self.from_request(request, site:)
      accept_language = RequestHeader.joined(request, 'accept-language')
      language = Translations.negotiate(accept_language: (accept_language unless accept_language&.strip&.empty?), default: site.language)
      new(language:, region: site.region || cloudflare_country(request))
    end

    # The visitor's country by Cloudflare's CF-IPCountry header, or nil when there's none to go by, like XX for one it
    # can't place or T1 for one using Tor.
    def self.cloudflare_country(request)
      code = RequestHeader.first(request, 'cf-ipcountry')
      return nil if code.nil?

      code = code.to_s.upcase
      code if code.match?(/\A[A-Z]{2}\z/) && !%w[XX T1].include?(code)
    end
  end
end
