require 'spec_helper'
require 'lock_jar/bundler'

describe LockJar::Bundler do
  describe '.lock!' do
    before do
      File.delete('Jarfile.lock') if File.exist?('Jarfile.lock')
      LockJar::Bundler.lock!('spec/fixtures/Jarfile')
    end

    it 'should create Jarfile.lock' do
      expect(File).to exist('Jarfile.lock')
    end
  end
end
