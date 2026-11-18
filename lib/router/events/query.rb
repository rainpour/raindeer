# frozen_string_literal: true

require 'lowevent'
require 'uri'

module Rain
  module Events
    # A request's query string, like "q=rye" in "/search?q=rye", as a hash with symbol keys, for the events made from it.
    module Query
      class << self
        # A request's path without its query string, which routes match on.
        def path(request)
          request.path.split('?', 2).first
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
    end

    Low::Events::RenderEvent.include(Query)
  end
end
