# frozen_string_literal: true

require 'lowevent'
require_relative '../../sites/site'
require_relative '../../sites/locale'

module Rain
  module Events
    # The site a request came to and who its response is for, for the events made from it, like a RouteEvent or a child
    # node's RenderEvent: event.site.origin to link back to it, and event.locale.region for a visitor's country.
    module Sites
      def site
        request && Rain::Site.from_request(request)
      end

      def locale
        request && Rain::Locale.from_request(request, site:)
      end
    end

    Low::Events::RenderEvent.include(Sites)
    Low::Events::StatusEvent.include(Sites)
  end
end
