# frozen_string_literal: true

require 'observers'
require 'lowevent'
require 'providers'

require_relative '../../../lib/router/router'

RSpec.describe Rain::Events::RouteEvent do
  let(:router) { Rain::Router.new }
  let(:page) { Class.new { include Observers } }
  let(:recipes) { Class.new { include Observers } }
  let(:wildcard) { Class.new { include Observers } }

  before do
    Observers::Keys.reset
    allow(Providers).to receive(:[]).with('rain.router').and_return(router)
    router.route '/about'
    router.route '/recipes'
    router.route '/*'
    page.observe '/about'
    wildcard.observe '/*'
    recipes.observe '/recipes'
  end

  it 'lists what observes its routes once each without what observes "/*"' do
    expect(described_class.observers.to_a.map(&:object)).to eq([page, recipes])
  end

  it "lists one route's observers by its path" do
    expect(described_class.observers('/recipes').to_a.map(&:object)).to eq([recipes])
  end
end
