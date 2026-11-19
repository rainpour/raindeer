# frozen_string_literal: true

require 'antlers'
require 'lownode'
require 'openssl'
require 'protocol/http'
require 'securerandom'
require 'uri'
require_relative '../router/events/body'

module Rain
  # Anti-forgery tokens, so a form another site posts here, with a visitor's cookies, is turned away. Each browser gets
  # a random key in a cookie, and a form's token is an HMAC of that key with the app's secret, which Antlers puts in a
  # hidden form_token field. Another site can't read the cookie or know the secret, so it can't make the token.
  #
  # It observes RequestEvent before the router: it turns a forged form away, and on the response's way out, sets the
  # cookie for a key it gave out while the page rendered, which it keeps in the RequestEvent's store.
  module FormTokens
    COOKIE = 'form_key'
    FIELD = 'form_token' # The hidden field Antlers gives each POST form.
    # The bodies a form on another site can send without the browser asking this site first. Others, like JSON, can't.
    FORM_TYPES = %w[application/x-www-form-urlencoded multipart/form-data text/plain].freeze
    SAFE_METHODS = %w[GET HEAD OPTIONS].freeze
    KEY_AGE = 365 * 24 * 3600

    class << self
      attr_writer :secret

      # A form posted without the token for its browser's key goes no further than a 403: the app's page for it, or a
      # plain one when it has none, so the request never reaches the router.
      def request(event:)
        return if valid?(event.request)

        Low::Events::StatusEvent.take(status: Low::Types::Status[403], request: event.request) || forbidden
      end

      # Sets the cookie for a key given out while the request was answered.
      def response(event:, result:)
        cookie = cookie(event)
        result.response.headers.add('set-cookie', cookie) if cookie && result.respond_to?(:response)
      end

      # The secret from RAIN_SECRET. Without one, a random secret lasts until the server restarts, so a form opened
      # before a restart is turned away after it.
      def secret
        @secret ||= ENV.fetch('RAIN_SECRET') { SecureRandom.hex(32) }
      end

      # The token for a RequestEvent's forms. A browser without a key is given one with the response.
      def token(request_event)
        key = browser_key(request_event.request) || (request_event.store[:form_key] ||= SecureRandom.urlsafe_base64(32))
        hmac(key)
      end

      # Whether a request may go on: anything but a form posted without the token for its browser's key.
      def valid?(request)
        return true if SAFE_METHODS.include?(request.method) || !FORM_TYPES.include?(media_type(request))

        key = browser_key(request)
        sent = sent_token(request)
        return false unless key && sent && sent.bytesize == hmac(key).bytesize

        OpenSSL.secure_compare(hmac(key), sent)
      end

      # The Set-Cookie header for a key given out while answering a RequestEvent, or nil.
      def cookie(request_event)
        key = request_event.store.delete(:form_key)
        return unless key

        Low::Responses::Cookie.new(name: COOKIE, value: key, max_age: KEY_AGE, secure: https?(request_event.request)).to_s
      end

      private

      def forbidden
        headers = Protocol::HTTP::Headers[{ 'content-type' => 'text/plain' }]
        body = Protocol::HTTP::Body::Buffered.wrap("This form has expired. Go back, reload the page and send it again.\n")
        Low::Events::ResponseEvent.new(response: Protocol::HTTP::Response.new('HTTP/1.1', 403, headers, body))
      end

      def hmac(key)
        OpenSSL::HMAC.hexdigest('SHA256', secret, key)
      end

      def browser_key(request)
        Array(request.headers['cookie']).flat_map { |header| header.split(';') }.each do |cookie|
          name, value = cookie.strip.split('=', 2)
          return URI.decode_www_form_component(value.to_s) if name == COOKIE && !value.to_s.empty?
        end
        nil
      end

      def sent_token(request)
        body = Events::Body.read(request)
        case media_type(request)
        when 'application/x-www-form-urlencoded' then URI.decode_www_form(body).assoc(FIELD)&.last
        when 'multipart/form-data' then body[/name="#{FIELD}"\r?\n\r?\n([^\r\n]*)/, 1]
        else body[/^#{FIELD}=([^\r\n]*)/, 1]
        end
      rescue ArgumentError
        nil
      end

      def media_type(request)
        Array(request.headers['content-type']).first&.split(';')&.first&.strip&.downcase
      end

      # Behind a proxy like Caddy, the proxy says whether the browser used HTTPS.
      def https?(request)
        Array(request.headers['x-forwarded-proto']).first == 'https' || request.scheme == 'https'
      end
    end
  end

  # Antlers asks for the token of the request being answered.
  Antlers.form_token = lambda do
    request_event = Low::Events::RequestEvent.current
    FormTokens.token(request_event) if request_event
  end
end
