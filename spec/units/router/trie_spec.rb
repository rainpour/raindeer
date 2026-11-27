# frozen_string_literal: true

require_relative '../../factories/request_factory'
require_relative '../../../lib/router/events/route_event'
require_relative '../../../lib/router/route'
require_relative '../../../lib/router/trie'

module Rain
  RSpec.describe Trie do
    subject(:trie) { described_class.new }

    def matching_node(node:, path:)
      return node if node.route&.path == path

      node.nodes.values.map do |child_node|
        matching_node(node: child_node, path:)
      end.compact.first
    end

    describe '#merge' do
      it 'creates the root path node' do
        trie.merge(route: Route.new(path: '/'))
        expect(trie.root_path_node.route).to have_attributes(path: '/')
      end

      it 'creates a prefix tree of nodes' do
        trie.merge(route: Route.new(path: '/users'))
        trie.merge(route: Route.new(path: '/users/:id'))
        trie.merge(route: Route.new(path: '/users/:id/edit'))

        expect(trie.root_path_node.nodes.keys.first).to eq('u')
        expect(trie.root_path_node.nodes.values.first.nodes.keys.first).to eq('s')
        expect(trie.root_path_node.nodes.values.first.nodes.values.first.nodes.keys.first).to eq('e')

        expect(matching_node(node: trie.root_path_node, path: '/users')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id/edit')).to be_truthy
      end
    end

    describe '#match' do
      context 'with a static route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/users', verb: 'GET') }

        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users'))

          expect(trie.match(request:)).to all(be_instance_of(Events::RouteEvent))
          expect(trie.match(request:).first.route).to have_attributes(path: '/users')
        end
      end

      context 'with a query string' do
        let(:request) { Low::Support::RequestFactory.request(path: '/users/1?tab=posts', verb: 'GET') }

        it 'matches the path without it, to render' do
          trie.merge(route: Route.new(path: '/users/:id'))

          event = trie.match(request:).last
          expect(event.route).to have_attributes(path: '/users/:id')
          expect([event.params, event.actions.first]).to eq([{ id: '1' }, :render])
        end
      end

      context 'with a static/dynamic route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/users/1', verb: 'GET') }

        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users/:id'))

          expect(trie.match(request:)).to all(be_instance_of(Events::RouteEvent))
          expect(trie.match(request:).first.route).to have_attributes(path: '/users/:id')
        end
      end

      context 'with a dynamic route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/username', verb: 'GET') }

        context 'when single level' do
          it 'creates a route event' do
            trie.merge(route: Route.new(path: '/:user_id'))

            expect(trie.match(request:).first.route).to have_attributes(path: '/:user_id')
            expect(trie.match(request:).first.params).to eq(user_id: 'username')
          end
        end

        context 'when double level' do
          let(:request) { Low::Support::RequestFactory.request(path: '/username/123', verb: 'GET') }

          it 'creates a route event' do
            trie.merge(route: Route.new(path: '/:user_id/:post_id'))

            expect(trie.match(request:).first.route).to have_attributes(path: '/:user_id/:post_id')
            expect(trie.match(request:).first.params).to eq(user_id: 'username', post_id: '123')
          end
        end
      end

      context 'with overlapping routes' do
        let(:request) { Low::Support::RequestFactory.request(path: '/users/1', verb: 'GET') }

        before do
          trie.merge(route: Route.new(path: '/users'))
          trie.merge(route: Route.new(path: '/users/:id'))
        end

        it 'creates multiple route events' do
          expect(trie.match(request:)).to all(be_instance_of(Events::RouteEvent))
          expect(trie.match(request:).first.route).to have_attributes(path: '/users')
          expect(trie.match(request:).last.route).to have_attributes(path: '/users/:id')
        end

        context 'when :param is an end node' do
          let(:request) { Low::Support::RequestFactory.request(path: '/users/1', verb: 'GET') }

          it "sets the mid node's event action to #side_effect" do
            # /users
            route_event = trie.match(request:).first
            expect(route_event).to have_attributes(actions: [:side_effect])
          end

          it "sets the end node's event action to #render" do
            route_event = trie.match(request:).last # => /users/:id
            expect(route_event).to have_attributes(actions: [:render, :get])
          end

          context 'when :param is a mid node' do
            let(:request) { Low::Support::RequestFactory.request(path: '/users/1/edit', verb: 'GET') }

            before do
              trie.merge(route: Route.new(path: '/users/:id/edit'))
            end

            it "sets the mid node's event action to #side_effect" do
              route_event = trie.match(request:)[1] # => /users/:id
              expect(route_event).to have_attributes(actions: [:side_effect])
            end

            it "sets the end node's event action to #render" do
              route_event = trie.match(request:).last # => /users/:id/edit
              expect(route_event).to have_attributes(actions: [:render, :get])
            end

            it 'matches each route once, though two routes have the param' do
              paths = trie.match(request:).map { |route_event| route_event.route.path }
              expect(paths).to eq(['/users', '/users/:id', '/users/:id/edit'])
            end
          end
        end
      end

      context 'with a route that starts with the letters of another' do
        before do
          trie.merge(route: Route.new(path: '/'))
          trie.merge(route: Route.new(path: '/post'))
          trie.merge(route: Route.new(path: '/posts'))
          trie.merge(route: Route.new(path: '/posts/:id'))
        end

        it "doesn't match the shorter route as a mid node" do
          request = Low::Support::RequestFactory.request(path: '/posts', verb: 'GET')
          paths = trie.match(request:).map { |route_event| route_event.route.path }
          expect(paths).to eq(['/', '/posts'])
        end

        it 'still matches whole segments as mid nodes' do
          request = Low::Support::RequestFactory.request(path: '/posts/1', verb: 'GET')
          paths = trie.match(request:).map { |route_event| route_event.route.path }
          expect(paths).to eq(['/', '/posts', '/posts/:id'])
        end
      end

      context 'with a :param after a character in its segment' do
        before do
          trie.merge(route: Route.new(path: '/@:username'))
          trie.merge(route: Route.new(path: '/@:username/posts/:id'))
          trie.merge(route: Route.new(path: '/@admin'))
        end

        def route_events(path)
          request = Low::Support::RequestFactory.request(path:, verb: 'GET')
          trie.match(request:).map { |route_event| [route_event.route.path, route_event.params] }
        end

        it 'matches the rest of the segment as the :param' do
          expect(route_events('/@maedi')).to eq([['/@:username', { username: 'maedi' }]])
        end

        it 'matches routes below it' do
          expect(route_events('/@maedi/posts/3').last).to eq(['/@:username/posts/:id', { username: 'maedi', id: '3' }])
        end

        it 'matches a static route that is the whole segment, rather than the :param' do
          expect(route_events('/@admin')).to eq([['/@admin', {}]])
        end

        it 'matches the :param when the static route only starts the same' do
          expect(route_events('/@admins')).to eq([['/@:username', { username: 'admins' }]])
        end
      end

      context 'with a static segment next to a :param' do
        before do
          trie.merge(route: Route.new(path: '/dispatches/:id'))
          trie.merge(route: Route.new(path: '/dispatches/by_involved_entity/:id'))
        end

        def matched(path)
          request = Low::Support::RequestFactory.request(path:, verb: 'GET')
          trie.match(request:).map { |event| [event.route.path, event.params, event.actions.first] }
        end

        it 'matches the static segment rather than the :param' do
          expect(matched('/dispatches/by_involved_entity/R-1')).to eq([['/dispatches/by_involved_entity/:id', { id: 'R-1' }, :render]])
        end

        it 'matches the :param when the static segment differs' do
          expect(matched('/dispatches/D-1')).to eq([['/dispatches/:id', { id: 'D-1' }, :render]])
        end

        it 'matches the :param when the static segment only starts the same' do
          expect(matched('/dispatches/by_id')).to eq([['/dispatches/:id', { id: 'by_id' }, :render]])
        end

        it 'matches the :param when the static segment is the whole value' do
          expect(matched('/dispatches/by_involved_entity')).to eq([['/dispatches/:id', { id: 'by_involved_entity' }, :render]])
        end
      end

      context 'with routes that capture more params further along' do
        let(:request) { Low::Support::RequestFactory.request(path: '/mark/42', verb: 'GET') }

        it 'gives each route event only the params of its own route' do
          trie.merge(route: Route.new(path: '/:user_id'))
          trie.merge(route: Route.new(path: '/:user_id/:post_id'))

          expect(trie.match(request:).map(&:params)).to eq([{ user_id: 'mark' }, { user_id: 'mark', post_id: '42' }])
        end
      end
    end
  end
end
