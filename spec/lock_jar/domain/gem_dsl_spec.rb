require 'spec_helper'
require 'lock_jar/domain/gem_dsl'

describe LockJar::Domain::GemDsl do
  describe '.create' do
    let(:spec) do
      double(:spec, gem_dir: 'spec/fixtures', name: 'test')
    end

    it 'should create from a block' do
      jarfile = LockJar::Domain::GemDsl.create(spec, File.join(spec.gem_dir, 'Jarfile')) do
        pom 'pom.xml'
      end

      expect(jarfile.gem_dir).to eql 'spec/fixtures'
    end
  end
end
