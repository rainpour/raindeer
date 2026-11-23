# frozen_string_literal: true

module System
  # Numbers as the system pages show them.
  module Numbers
    # A large number with commas between its thousands, like 1,234,567.
    def self.delimited(number)
      number.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
    end
  end
end
