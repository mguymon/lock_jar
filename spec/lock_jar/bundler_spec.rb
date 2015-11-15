require 'spec_helper'
require 'lock_jar/bundler'

describe LockJar::Bundler do
  include Spec::Helpers

  before do
    remove_file('Jarfile.lock')
    LockJar::Bundler.lock!('spec/fixtures/Jarfile')
  end

  describe '.lock!' do
    it 'should create Jarfile.lock' do
      expect(File).to exist('Jarfile.lock')
    end
  end

  describe '.load' do
    it 'should load jars' do
      LockJar::Bundler.load('test')

      expected_jars = %w(junit:junit:jar:4.10 org.hamcrest:hamcrest-core:jar:1.1)

      expect(LockJar::Registry.instance.loaded_jars).to eql(expected_jars)
    end
  end
end
