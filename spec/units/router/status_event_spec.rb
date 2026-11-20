# frozen_string_literal: true

require 'protocol/http'
require_relative '../../../lib/router/events/cookies'
require_relative '../../../lib/router/events/query'

RSpec.describe Low::Events::StatusEvent do
  it "gives its request's cookies, address and query, for a status's page like a 404's" do
    headers = Protocol::HTTP::Headers[{ 'cookie' => 'session=abc' }]
    request = Protocol::HTTP::Request.new('http', nil, 'GET', '/forum/missing-rye%20loaf?page=2', nil, headers, nil)
    event = described_class.new(status: Low::Types::Status[404], request:)

    expect([event.cookies['session'], event.path, event.query]).to eq(['abc', '/forum/missing-rye loaf', { page: '2' }])
  end
end
