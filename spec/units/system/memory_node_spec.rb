# frozen_string_literal: true

require 'observers'
require 'lownode'
require 'dirload'
require 'antlers'
require_relative '../../../lib/raindeer/integrations'

dirload(File.join(Dir.pwd, '/lib/system/memory_node.rb'))
dirload(File.join(Dir.pwd, '/lib/system/numbers.rb'))
dirload(File.join(Dir.pwd, '/lib/system/formatters/trend_formatter.rbx'))

RSpec.describe System::MemoryNode do
  before { described_class.instance_variable_set(:@samples, []) }

  it 'observes an interval each minute' do
    Observers::Keys.reset
    load File.join(Dir.pwd, '/lib/system/memory_node.rb')
    expect(Observers::Keys[Low::Loop::Interval[every_minute: 1]].observers.map(&:object)).to include(described_class)
  end

  it 'samples the memory the process holds and the keys Observers holds' do
    sample = described_class.current
    expect([sample.megabytes.positive?, sample.keys == Observers::Keys.keys.size]).to eq([true, true])
  end

  it 'keeps the last 3 hours of samples a minute apart' do
    181.times do |minute|
      described_class.record(described_class::Sample.new(at: minute, megabytes: minute, keys: 1, objects: 1, retained: 1))
    end
    samples = described_class.samples
    expect([samples.size, samples.first.megabytes, samples.last.megabytes]).to eq([180, 1, 180])
  end

  it 'samples on each tick' do
    described_class.tick(event: nil)
    expect(described_class.samples.size).to eq(1)
  end
end

RSpec.describe TrendFormatter do
  it 'draws the lowest value at the bottom and the highest at the top across the whole width' do
    points = described_class.new(event: nil, title: 'Memory', values: [100, 150, 200]).instance_variable_get(:@points)
    expect(points).to eq('0.0,76.0 300.0,40.0 600.0,4.0')
  end

  it 'draws values that never change and a lone value as a flat line across the middle' do
    points = [[62, 62], [62]].map { described_class.new(event: nil, title: 'Keys', values: it).instance_variable_get(:@points) }
    expect(points).to eq(['0.0,40.0 600.0,40.0'] * 2)
  end
end
