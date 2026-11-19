# frozen_string_literal: true

require 'protocol/http'
require_relative '../../../lib/router/events/receive_event'
require_relative '../../../lib/router/route'

module Rain
  module Events
    RSpec.describe Multipart do
      subject(:event) { ReceiveEvent.new(route: Route.new(path: '/photos'), request:, actions: %i[receive post]) }

      let(:request) do
        headers = Protocol::HTTP::Headers[{ 'content-type' => 'multipart/form-data; boundary=----antler' }]
        Protocol::HTTP::Request.new('http', nil, 'POST', '/photos', nil, headers, Protocol::HTTP::Body::Buffered.wrap(body))
      end
      let(:png) { "\x89PNG\r\n\x1A\n\x00\xFF".b }
      let(:body) do
        [part('name="caption"', 'Red nose'), part('name="photo"; filename="a.png"', png, 'image/png'),
         part('name="photo"; filename="b.png"', png, 'image/png'), part('name="empty"; filename=""', ''),
         "------antler--\r\n"].join.b
      end

      def part(disposition, data, type = nil)
        content_type = "Content-Type: #{type}\r\n" if type
        "------antler\r\nContent-Disposition: form-data; #{disposition}\r\n#{content_type}\r\n#{data}\r\n".b
      end

      it 'gives its fields, its files with their name, type and bytes, and repeated names as an array' do
        expect(event.body[:caption]).to eq('Red nose')
        expect(event.body[:photo].map { [it.filename, it.content_type, it.data] })
          .to eq([['a.png', 'image/png', png], ['b.png', 'image/png', png]])
        expect(event.body).not_to have_key(:empty)
      end
    end
  end
end
