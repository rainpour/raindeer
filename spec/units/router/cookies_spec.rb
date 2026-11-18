# frozen_string_literal: true

require 'protocol/http'
require_relative '../../../lib/router/events/route_event'
require_relative '../../../lib/router/events/wildcard_event'
require_relative '../../../lib/router/route'

module Rain
  module Events
    RSpec.describe Cookies do
      let(:route) { Route.new(path: '/') }
      let(:request) do
        headers = Protocol::HTTP::Headers[cookie ? { 'cookie' => cookie } : {}]
        Protocol::HTTP::Request.new('http', nil, 'GET', '/', nil, headers, nil)
      end
      let(:cookie) { 'session=a+b%3D; theme=dark' }

      it "reads a route event's request's cookies" do
        expect(RouteEvent.new(route:, request:).cookies).to eq({ 'session' => 'a b=', 'theme' => 'dark' })
      end

      it "reads a child node's render event's request's cookies" do
        expect(Low::Events::RenderEvent.new(request:).cookies['session']).to eq('a b=')
      end

      it "reads a wildcard event's request's cookies" do
        expect(WildcardEvent.new(key: '/*', route:, request:).cookies['theme']).to eq('dark')
      end

      context 'without cookies' do
        let(:cookie) { nil }

        it 'has none' do
          expect(RouteEvent.new(route:, request:).cookies).to eq({})
        end
      end

      it 'has none without a request' do
        expect(RouteEvent.new(route:).cookies).to eq({})
      end
    end
  end
end
