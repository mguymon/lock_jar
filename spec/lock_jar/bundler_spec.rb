require 'spec_helper'
require 'lock_jar/bundler'

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
end
