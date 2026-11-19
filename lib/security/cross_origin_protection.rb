# frozen_string_literal: true

require 'lowevent'
require 'protocol/http'
require 'uri'

module Rain
  # Turns away a request that another site's page makes, like a form it posts here with a visitor's cookies, before it
  # reaches the router. Browsers say where a request came from in Sec-Fetch-Site, which a page can't change. Older
  # browsers send Origin instead. A request with neither isn't from a browser, like a webhook's, so it goes through.
  module CrossOriginProtection
    SAFE_METHODS = %w[GET HEAD OPTIONS].freeze
    # From this site's own pages, or typed in, or from a bookmark.
    SAME_SITE_FETCHES = %w[same-origin none].freeze

    class << self
      # A request from another site goes no further than a 403: the app's page for it, or a plain one when it has none.
      def request(event:)
        return if same_origin?(event.request)

        Low::Events::StatusEvent.take(status: Low::Types::Status[403], request: event.request) || forbidden
      end

      # Whether a request may go on: anything that doesn't change things, or that comes from this site or no browser.
      def same_origin?(request)
        return true if SAFE_METHODS.include?(request.method)

        fetch_site = header(request, 'sec-fetch-site')
        return SAME_SITE_FETCHES.include?(fetch_site) if fetch_site

        origin = header(request, 'origin')
        origin.nil? || authority(origin) == header(request, 'host')
      end

      private

      def forbidden
        headers = Protocol::HTTP::Headers[{ 'content-type' => 'text/plain' }]
        body = Protocol::HTTP::Body::Buffered.wrap("This was sent from another site, so it wasn't accepted.\n")
        Low::Events::ResponseEvent.new(response: Protocol::HTTP::Response.new('HTTP/1.1', 403, headers, body))
      end

      def header(request, name)
        Array(request.headers[name]).first
      end

      # An origin's host, and its port when it isn't the scheme's usual one, as a Host header has them.
      def authority(origin)
        uri = URI(origin)
        return uri.host if uri.port == uri.default_port

        "#{uri.host}:#{uri.port}"
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
