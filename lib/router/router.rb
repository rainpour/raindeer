# frozen_string_literal: true

require 'lowevent'

require_relative 'events/route_event'
require_relative 'events/wildcard_event'
require_relative 'http'
require_relative 'route'
require_relative 'trie'
require_relative '../translations/translations'
require_relative 'events/sites'

module Rain
  # Defines routes and routes requests to a matching route event.
  class Router
    include LowType
    include Observers
    include Low::Events
    include Low::Types
    include Rain::HTTP

    attr_reader :routes, :trie

    def initialize
      @current_level = []
      @routes = {}
      @trie = Trie.new
    end

    def route(value, &block)
      path, verbs = Route.decode(value:)

      @current_level << path
      path = @current_level.join

      route = Route.new(path:, verbs:)
      @routes[path] = route
      @trie.merge(route:)

      block.call if block_given?

      @current_level.pop
    end

    # A route for each HTTP verb, like "put '/path'".
    VERBS.each do |verb|
      define_method(verb) do |path, &block|
        route(verb => path, &block)
      end
    end

    def request(event: RequestEvent)
      locale = Rain::Locale.from_request(event.request, site: Rain::Site.from_request(event.request)).language

      response_event = Antlers::Translations.with_locale(locale) do
        respond(request: event.request)
      end
      language_headers(response: response_event.response, locale:) if response_event.is_a?(ResponseEvent)

      response_event
    end

    private

    def language_headers(response:, locale:)
      return unless response
      return if Antlers::Translations.locales.empty?

      headers = response.headers
      headers.add('vary', 'accept-language')
      headers.add('content-language', locale) unless headers.include?('content-language')
    end

    # A parent route's side_effect is skipped when no node observing the route has one, as it would do nothing but still
    # go through the event tree. An observer that can't say, like an object that isn't a node, or one that observes it
    # with an action of its own, is always given it.
    def handled?(route_event)
      return true unless route_event.actions.first == :side_effect

      Observers::Keys[route_event.key].observers.any? do |observer|
        object = observer.object
        observer.action || !object.respond_to?(:handles?) || object.handles?(:side_effect)
      end
    end

    def respond(request:)
      response_event = nil

      # The last route event will render a response event which we want to return to the request event.
      @trie.match(request:).each do |route_event|
        next unless handled?(route_event)

        response_event = route_event.take
      end
      return response_event if response_event

      wildcard = @routes[Events::WildcardEvent::KEY]
      if wildcard
        route = Route.new(path: Events::Query.path(request), verbs: wildcard.verbs)
        action = :render
        action = :receive if request.body
        wildcard_event = Events::WildcardEvent.take(key: Events::WildcardEvent::KEY, action:, route:, request:)
        return wildcard_event if wildcard_event
      end

      StatusEvent.take(status: Status[404], request:)
    end
  end
end
