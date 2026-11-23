# frozen_string_literal: true

module System
  # Where a request came from, as a proxy like Cloudflare or Caddy says in a header. The first header found wins, and
  # x-forwarded-for lists each proxy after the visitor, so the first address in it is theirs.
  module VisitorAddress
    HEADERS = %w[cf-connecting-ip x-forwarded-for x-real-ip].freeze

    def self.from(headers)
      header = HEADERS.find { |name| headers&.include?(name) }
      return unless header

      Array(headers[header]).join(',').split(',').first&.strip
    end
  end
end
