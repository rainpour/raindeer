# frozen_string_literal: true

require_relative 'events/receive_event'
require_relative 'events/route_event'
require_relative 'route'
require_relative 'trie_node'

module Rain
  class Trie
    include LowType

    PARAM_DELIMITERS = ['/', ':'].freeze
    SLASH = '/'.ord
    # A request method's action, like :get for "GET", made once rather than for every request. Only the standard
    # methods, as a client can send any method and a cache of them all would grow without end.
    METHOD_ACTIONS = %w[GET HEAD POST PUT PATCH DELETE OPTIONS QUERY].to_h { [it, it.downcase.to_sym] }.freeze

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

    # The path is decoded once per request, and its characters are read as codepoints, which are integers rather than
    # a new string for each character.
    def match(request:, path: nil)
      path ||= Events::Query.path(request)

      walk(@root_node, 0, {}, request, path, path.codepoints)
    end

    private

    # Walks the path's characters down the trie in a loop, with the route events of the routes passed through on the
    # way, until a node has a :param child, where the path can go more than one way.
    def walk(node, index, params, request, path, codes) # rubocop:disable Metrics/ParameterLists
      events = []

      while (code = codes[index])
        static_node = node.code_child(code)
        return events.concat(branch(node, static_node, index, params, request, path, codes)) if node.params?
        return events unless static_node

        index += 1
        events << route_event(index, params, request, static_node.route, codes) if route_end?(static_node, codes, index)
        node = static_node
      end

      events
    end

    # A static request path segment wins over a :param when it matches a route to the end of the path, like
    # "/posts/drafts/7" for "/posts/drafts/:id" rather than "/posts/:id". Each :param has its own params, so one route's
    # arg isn't another's.
    def branch(node, static_node, index, params, request, path, codes) # rubocop:disable Metrics/ParameterLists
      static_events = static_node ? events_from(static_node, index + 1, params, request, path, codes) : []
      return static_events if ends?(static_events)

      dynamic_events = node.params.flat_map do |param|
        arg, next_index = capture_arg(index, path, codes)
        param_params = params.merge(param.delete_prefix(':').to_sym => arg)

        events_from(node.child(key: param), next_index, param_params, request, path, codes)
      end
      # The static events were a different path from here, so when a :param matches to the end only its events count.
      return dynamic_events if ends?(dynamic_events)

      static_events + dynamic_events
    end

    # The node's own route event, if it has a route that ends on a whole segment of the path, then those of the routes
    # below it. The trie is by character, so "/solo1" is passed through on the way to "/solo10" but isn't its parent.
    def events_from(node, next_index, params, request, path, codes) # rubocop:disable Metrics/ParameterLists
      events = route_end?(node, codes, next_index) ? [route_event(next_index, params, request, node.route, codes)] : []
      events.concat(walk(node, next_index, params, request, path, codes))
    end

    def route_end?(node, codes, next_index)
      node.route && segment_end?(codes, next_index)
    end

    # Whether the path ends here or a new segment starts here, or the route itself ended with a "/", like "/".
    def segment_end?(codes, next_index)
      next_code = codes[next_index]
      next_code.nil? || next_code == SLASH || codes[next_index - 1] == SLASH
    end

    # Whether a route was matched to the end of the path, to render or receive rather than only for its side effects.
    def ends?(route_events)
      route_events.any? { |route_event| route_event.actions.first != :side_effect }
    end

    # Mid nodes side_effect, end nodes render.
    def route_event(next_index, params, request, route, codes)
      action = codes[next_index].nil? ? :render : :side_effect
      action = :receive if action == :render && request.body

      actions = [action]
      actions << (METHOD_ACTIONS[request.method] || request.method.downcase.to_sym) unless action == :side_effect

      return Events::ReceiveEvent.new(actions:, route:, params:, request:) if action == :receive

      Events::RouteEvent.new(actions:, route:, params:, request:)
    end

    # An arg is at least one character, up to the next "/" or the end of the path.
    def capture_arg(arg_start_index, path, codes)
      next_index = arg_start_index + 1
      next_index += 1 while (code = codes[next_index]) && code != SLASH

      [path[arg_start_index...next_index], next_index]
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
  end
end
