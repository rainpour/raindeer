# frozen_string_literal: true

require_relative 'events/receive_event'
require_relative 'events/route_event'
require_relative 'route'
require_relative 'trie_node'

module Rain
  class Trie
    include LowType

    PARAM_DELIMITERS = ['/', ':'].freeze
    ARG_DELIMITERS = ['/'].freeze

    attr_reader :root_node

    def initialize
      @root_node = TrieNode.new
    end

    def root_path_node
      @root_node.nodes['/']
    end

    def merge(route:, current_node: @root_node, current_index: 0)
      path = route.path

      while current_index < path.length
        key = path[current_index]

        if key == ':'
          key, current_index = capture_param(current_index:, path:)
        else
          current_index += 1
        end

        current_node = current_node.upsert_child(key:)
      end

      current_node.route = route
    end

    # The path is decoded once per request and passed down, rather than for every character matched.
    def match(request:, current_node: @root_node, current_index: 0, params: {}, path: nil)
      path ||= Events::Query.path(request)

      return [] if (key = path[current_index]).nil?

      # Static request path segment, which wins over a :param when it matches a route to the end of the path,
      # like "/posts/drafts/7" for "/posts/drafts/:id" rather than "/posts/:id".
      static_node = current_node.child(key:)
      static_events = static_node ? events_from(node: static_node, next_index: current_index + 1, params:, request:, path:) : []
      return static_events if ends?(static_events)

      # Dynamic request path segment, each with its own params, so one route's arg isn't another's.
      dynamic_events = current_node.params.flat_map do |param|
        arg, next_index = capture_arg(arg_start_index: current_index, path:)
        param_params = params.merge(param.delete_prefix(':').to_sym => arg)

        events_from(node: current_node.child(key: param), next_index:, params: param_params, request:, path:)
      end
      # The static events were a different path from here, so when a :param matches to the end only its events count.
      return dynamic_events if ends?(dynamic_events)

      [*static_events, *dynamic_events]
    end

    private

    # The node's own route event, if it has a route that ends on a whole segment of the path, then those of the routes
    # below it. The trie is by character, so "/solo1" is passed through on the way to "/solo10" but isn't its parent.
    def events_from(node:, next_index:, params:, request:, path:)
      route_events = []
      route_events << route_event(next_index:, params:, request:, route: node.route, path:) if node.route && segment_end?(path:, next_index:)
      route_events.concat(match(request:, current_node: node, current_index: next_index, params:, path:))
    end

    # Whether the path ends here or a new segment starts here, or the route itself ended with a "/", like "/".
    def segment_end?(path:, next_index:)
      next_char = path[next_index]
      next_char.nil? || next_char == '/' || path[next_index - 1] == '/'
    end

    # Whether a route was matched to the end of the path, to render or receive rather than only for its side effects.
    def ends?(route_events)
      route_events.any? { |route_event| route_event.actions.first != :side_effect }
    end

    # Mid nodes side_effect, end nodes render.
    def route_event(next_index:, params:, request:, route:, path:)
      action = path[next_index].nil? ? :render : :side_effect
      action = :receive if action == :render && request.body

      actions = [action]
      actions << request.method.downcase.to_sym unless action == :side_effect

      return Events::ReceiveEvent.new(actions:, route:, params:, request:) if action == :receive

      Events::RouteEvent.new(actions:, route:, params:, request:)
    end

    def capture_param(current_index:, path:)
      current_index += 1
      param = [':']

      path[current_index...path.length].chars.each do |char|
        break if PARAM_DELIMITERS.include?(char)

        current_index += 1
        param << char
      end

      [param.join, current_index]
    end

    def capture_arg(arg_start_index:, path:)
      next_index = arg_start_index
      arg = []

      path[arg_start_index...path.length].chars.each do |char|
        arg << char
        next_index += 1
        break if path[next_index].nil? || ARG_DELIMITERS.include?(path[next_index])
      end

      [arg.join, next_index]
    end
  end
end
