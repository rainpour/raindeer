# frozen_string_literal: true

require 'bundler'
require 'open3'

RSpec.describe 'Raindeer::VERSION' do
  # Without Bundler, as a released gem runs, where the gemspec that also reads lib/version.rb isn't loaded.
  it 'is loaded with Raindeer itself' do
    output, status = Bundler.with_unbundled_env do
      Open3.capture2e('ruby', '-Ilib', '-e', 'require "raindeer/raindeer"; print Raindeer::VERSION')
    end
    expect([status.success?, output]).to eq([true, File.read('lib/version.rb')[/VERSION = '(.+)'/, 1]])
  end
end
