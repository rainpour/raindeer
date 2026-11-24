# frozen_string_literal: true

require 'observers'
require 'lownode'
require 'dirload'
require 'antlers'
require_relative '../../../lib/raindeer/integrations'

dirload(File.join(Dir.pwd, '/lib/system/formatters/observers_formatter.rbx'))

RSpec.describe ObserversFormatter do
  let(:about_page) { Class.new { include Observers }.tap { |node| stub_const('AboutPage', node) } }

  before do
    Observers::Keys.reset
    about_page.observe '/about'
  end

  def observers_for(observer_key)
    described_class.new(event: nil, observer_key:).instance_variable_get(:@observers)
  end

  it "names what observes a route's path" do
    expect(observers_for('/about')).to eq(['AboutPage'])
  end

  it 'names what observes an event that answers for its own observers' do
    event = Class.new { include Observers }
    event.define_singleton_method(:observers) { |*| Observers::Keys.find('/about').observers }

    expect(observers_for(event)).to eq(['AboutPage'])
  end

  it 'names nothing for a key nothing observes' do
    expect(observers_for('/nowhere')).to eq([])
  end
end
