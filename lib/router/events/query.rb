# frozen_string_literal: true

require 'lowevent'
require 'uri'

module Rain
  module Events
    # A request's address and its query string, like /search and "q=rye" in "/search?q=rye", for the events made from it.
    # A route with a parameter, like /posts/:slug, has that as its route's path, so the address is the event's path.
    module Query
      class << self
        # A request's path without its query string, which routes match on. It's decoded, so /recipes/w%C3%BCnderbread
        # is /recipes/wünderbread, as content's paths are written. One that doesn't decode to UTF-8 stays as it came.
        def path(request)
          path = request.path.split('?', 2).first
          decoded = URI.decode_uri_component(path)
          return path unless decoded.valid_encoding?

          decoded
        rescue ArgumentError
          path
        end

        def parse(request)
          string = request&.path.to_s.split('?', 2)[1]
          return {} unless string

          URI.decode_www_form(string).to_h.transform_keys(&:to_sym)
        rescue ArgumentError
          {}
        end
      end

      def query
        Query.parse(request)
      end

      # The address the request came to, without its query, like /posts/proofing-oven for the route /posts/:slug.
      def path
        request && Query.path(request)
      end
    end

    Low::Events::RenderEvent.include(Query)
    # A status's page, like a 404's, knows the address it's for, so it can suggest what was meant.
    Low::Events::StatusEvent.include(Query)
  end
end
