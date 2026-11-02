# frozen_string_literal: true

require_relative '../../../lib/cli/template'

RSpec.describe Rain::CLI::Template do
  describe '.clone_progress' do
    it 'parses the percentage of received objects' do
      expect(described_class.clone_progress("Receiving objects:  45% (274/608), 120.00 KiB | 1.20 MiB/s\r")).to eq(45)
    end

    it 'ignores other git output' do
      expect(described_class.clone_progress("Resolving deltas: 100% (12/12)\r")).to be_nil
    end
  end
end
