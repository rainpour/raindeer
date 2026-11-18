# frozen_string_literal: true

require 'protocol/http'
require_relative '../../../lib/router/events/route_event'
require_relative '../../../lib/router/events/wildcard_event'
require_relative '../../../lib/router/route'

module Rain
  module Events
    RSpec.describe Query do
      def request(path)
        Protocol::HTTP::Request.new('http', nil, 'GET', path, nil, Protocol::HTTP::Headers.new, nil)
      end

      it "reads a route event's query" do
        event = RouteEvent.new(route: Route.new(path: '/search'), request: request('/search?q=rye+bread&page=2'))

        expect(event.query).to eq({ q: 'rye bread', page: '2' })
      end

      it "reads a wildcard event's and a render event's query" do
        expect(WildcardEvent.new(key: '/*', route: Route.new(path: '/'), request: request('/a?b=c')).query).to eq({ b: 'c' })
        expect(Low::Events::RenderEvent.new(request: request('/a?b=c')).query).to eq({ b: 'c' })
      end

      it 'has none without a query string' do
        expect(RouteEvent.new(route: Route.new(path: '/'), request: request('/')).query).to eq({})
      end

      it 'takes the query string off a path' do
        expect(described_class.path(request('/search?q=rye'))).to eq('/search')
      end
    end
  end
end
