require 'spec_helper'
require 'lock_jar/bundler'
require 'bundler/cli'
require 'bundler/cli/install'

describe LockJar::Bundler do
  include Spec::Helpers

  describe '.lock!' do
    before do
      remove_file('Jarfile.lock')
      LockJar::Bundler.lock!('spec/fixtures/Jarfile')
    end

    it 'should create Jarfile.lock' do
      expect(File).to exist('Jarfile.lock')
    end
  end

  describe '.lock_with_bundler' do
    it 'should call lock! from Bundler' do
      LockJar::Bundler.lock_with_bundler(test: :arg)
      expect(LockJar::Bundler).to receive(:lock!).with([{ test: :arg }])
      ::Bundler::CLI::Install.new({}).run
    end
  end
end
