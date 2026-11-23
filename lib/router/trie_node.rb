# frozen_string_literal: true

require_relative 'route'

module Rain
  class TrieNode
    include LowType
    using LowType::Syntax

    # TODO: Represent empty hash/array return value as {}/[] rather than Hash/Array (https://github.com/low-rb/low_type/issues/16)
    type_reader nodes: Hash[String => TrieNode] | Hash
    type_reader params: Array[String] | Array
    type_accessor route: Route | nil

    def initialize
      @nodes = {}
      @params = []
      @route = nil
    end

    def child(key: String)
      @nodes[key]
    end

    # A param is kept once, though more routes pass through it, like /users/:id and /users/:id/edit, or it'd match twice.
    def upsert_child(key: String)
      return @nodes[key] if @nodes.key?(key)

      @params << key if key.start_with?(':')
      @nodes[key] = TrieNode.new
    end
  end
end
