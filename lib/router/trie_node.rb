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
      @codes = {} # The same children as @nodes, by their character's codepoint, so a match needn't slice strings.
      @params = []
      @route = nil
    end

    def child(key: String)
      @nodes[key]
    end

    # The child for a character's codepoint, like 47 for "/". A :param child has none, as it isn't one character.
    def code_child(code)
      @codes[code]
    end

    def params?
      !@params.empty?
    end

    # A param is kept once, though more routes pass through it, like /users/:id and /users/:id/edit, or it'd match twice.
    def upsert_child(key: String)
      return @nodes[key] if @nodes.key?(key)

      node = TrieNode.new
      if key.start_with?(':')
        @params << key
      else
        @codes[key.ord] = node
      end
      @nodes[key] = node
    end
  end
end
