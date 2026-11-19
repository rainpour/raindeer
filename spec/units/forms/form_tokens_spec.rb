# frozen_string_literal: true

require 'protocol/http'
require_relative '../../../lib/forms/form_tokens'

RSpec.describe Rain::FormTokens do
  before { described_class.secret = 'test secret' }

  def request(method: 'POST', content_type: 'application/x-www-form-urlencoded', body: '', cookie: nil, proto: nil)
    headers = { 'content-type' => content_type, 'cookie' => cookie, 'x-forwarded-proto' => proto }.compact
    Protocol::HTTP::Request.new('http', nil, method, '/cart', nil, Protocol::HTTP::Headers[headers], Protocol::HTTP::Body::Buffered.wrap(body))
  end

  def request_event(**)
    Low::Events::RequestEvent.new(request: request(**))
  end

  # A browser's key and its token, as a page with a form gives them.
  def key_and_token
    page = request_event(method: 'GET')
    token = described_class.token(page)
    [described_class.cookie(page)[/form_key=([^;]+)/, 1], token]
  end

  it 'gives a browser without a key a new one as a cookie, once' do
    page = request_event(method: 'GET', proto: 'https')
    described_class.token(page)

    expect([described_class.cookie(page), described_class.cookie(page)])
      .to match([%r{\Aform_key=[\w-]+; Path=/; Max-Age=31536000; HttpOnly; Secure; SameSite=Lax\z}, nil])
  end

  it "gives the same token for a browser's key, and no new cookie" do
    key, token = key_and_token
    page = request_event(method: 'GET', cookie: "form_key=#{key}")

    expect([described_class.token(page), described_class.cookie(page)]).to eq([token, nil])
  end

  it 'lets in a form posted with its token, leaving the body for the node to read' do
    key, token = key_and_token
    posted = request(body: "quantity=2&form_token=#{token}", cookie: "other=1; form_key=#{key}")

    expect([described_class.valid?(posted), Rain::Events::Body.read(posted)]).to eq([true, "quantity=2&form_token=#{token}"])
  end

  it 'turns away a form posted without a token, as from another site' do
    key, = key_and_token

    expect(described_class.valid?(request(body: 'quantity=2', cookie: "form_key=#{key}"))).to be(false)
  end

  it "turns away another browser's token" do
    key, = key_and_token
    _, other_token = key_and_token

    expect(described_class.valid?(request(body: "form_token=#{other_token}", cookie: "form_key=#{key}"))).to be(false)
  end

  it 'turns away a form posted without a key' do
    _, token = key_and_token

    expect(described_class.valid?(request(body: "form_token=#{token}"))).to be(false)
  end

  it 'checks multipart and plain text forms too, which another site can also send' do
    key, token = key_and_token
    multipart = %(--x\r\nContent-Disposition: form-data; name="form_token"\r\n\r\n#{token}\r\n--x--\r\n)

    expect([
             described_class.valid?(request(content_type: 'multipart/form-data; boundary=x', body: multipart, cookie: "form_key=#{key}")),
             described_class.valid?(request(content_type: 'text/plain', body: "a=1\r\nform_token=#{token}", cookie: "form_key=#{key}")),
             described_class.valid?(request(content_type: 'text/plain', body: 'a=1', cookie: "form_key=#{key}"))
           ]).to eq([true, true, false])
  end

  it "lets in what a form can't send, like JSON, and what doesn't change anything, like GET" do
    expect([described_class.valid?(request(content_type: 'application/json', body: '{}')),
            described_class.valid?(request(method: 'GET'))]).to eq([true, true])
  end

  it 'gives Antlers the token of the request being answered, and none outside one' do
    page = request_event(method: 'GET')
    allow(Low::Events::RequestEvent).to receive(:current).and_return(page, nil)

    expect([Antlers.form_token.call, Antlers.form_token.call]).to eq([described_class.token(page), nil])
  end
end

RSpec.describe Rain::FormTokens, 'observing RequestEvent' do
  before { described_class.secret = 'test secret' }

  def request(method:, body: '')
    headers = Protocol::HTTP::Headers[{ 'content-type' => 'application/x-www-form-urlencoded' }]
    Protocol::HTTP::Request.new('http', nil, method, '/cart', nil, headers, Protocol::HTTP::Body::Buffered.wrap(body))
  end

  it 'answers a forged form with a plain 403 when the app has no page for it' do
    allow(Low::Events::StatusEvent).to receive(:take).and_return(nil)
    forged = Struct.new(:request).new(request(method: 'POST', body: 'quantity=2'))

    expect(described_class.request(event: forged).response.status).to eq(403)
  end

  it 'turns a forged form away with a 403, and lets anything else through to the router' do
    allow(Low::Events::StatusEvent).to receive(:take).and_return('403 page')
    forged = Struct.new(:request).new(request(method: 'POST', body: 'quantity=2'))

    expect([described_class.request(event: forged), described_class.request(event: Struct.new(:request).new(request(method: 'GET')))])
      .to eq(['403 page', nil])
  end

  it 'sets the cookie for a key it gave out on the way out' do
    page = Low::Events::RequestEvent.new(request: request(method: 'GET'))
    described_class.token(page)
    response = Protocol::HTTP::Response.new('HTTP/1.1', 200, Protocol::HTTP::Headers.new, nil)
    described_class.response(event: page, result: Low::Events::ResponseEvent.new(response:))

    expect(response.headers['set-cookie'].first).to start_with('form_key=')
  end
end
