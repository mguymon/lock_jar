require 'spec_helper'
require 'lock_jar/bundler'
require 'bundler/cli'
require 'bundler/cli/install'

describe LockJar::Bundler do
  include Spec::Helpers

  describe '.lock!' do
    let(:bundler) do
      Class.new { attr_accessor :setup }.new
    end

    before do
      remove_file('Jarfile.lock')
    end

    context 'when Bundler.install has run' do
      it 'should create Jarfile.lock' do
        LockJar::Bundler.lock!(bundler, 'spec/fixtures/Jarfile')
        expect(File).to exist('Jarfile.lock')
      end
    end

    context 'when Bundler.setup has run' do
      before { bundler.setup = true }

      it 'should create Jarfile.lock' do
        LockJar::Bundler.lock!(bundler, 'spec/fixtures/Jarfile')
        expect(File).to_not exist('Jarfile.lock')
      end
    end
  end
end
