# frozen_string_literal: true

require 'ostruct'
require 'yaml'

module Rain
  class ConfigLoader
    class << self
      def load(file_path, overrides = {})
        file_path = File.expand_path("config/#{file_path}", Dir.pwd) unless File.exist?(file_path)
        config_file = YAML.safe_load_file(file_path, permitted_classes: [Symbol], symbolize_names: true)

        # Environment variables override config file.
        config_data = config_file.merge(overrides) do |_key, old_value, new_value|
          new_value.nil? ? old_value : new_value
        end

        OpenStruct.new(config_data)
      end

      # Environment variables are strings, so "4133" becomes 4133.
      def parse_integer(value)
        return nil if value.nil?

        Integer(value, 10)
      rescue ArgumentError
        raise ArgumentError, "Expected an integer, got #{value.inspect}"
      end

      # Environment variables are strings, so "1" or "true" becomes true, and "0" or "false" false. Anything else is a
      # mistake, which would otherwise leave the config file's setting on without saying.
      def parse_boolean(value)
        return nil if value.nil?
        return true if %w[1 true].include?(value)
        return false if %w[0 false].include?(value)

        raise ArgumentError, "Expected 1, 0, true or false, got #{value.inspect}"
      end
    end
  end
end
