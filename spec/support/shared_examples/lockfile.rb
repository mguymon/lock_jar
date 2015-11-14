require 'spec_helper'

shared_examples 'a lockfile' do
  let(:lockfile_hash) { lockfile.to_h }

  it 'should have a version' do
    lockfile_hash['version'].should eql LockJar::VERSION
  end

  it 'should have a excludes' do
    if respond_to? :expected_excludes
      lockfile_hash['excludes'].should eql expected_excludes
    end
  end

  it 'should have a local repository' do
    if respond_to? :expected_local_repository
      expect(lockfile_hash['local_repository']).to(eql(expected_local_repository))
    end
  end

  it 'should have a maps' do
    expect(lockfile_hash['maps']).to(eql(expected_map)) if respond_to? :expected_map
  end

  it 'should have remote repositories' do
    lockfile_hash['remote_repositories'].should eql expected_remote_repositories
  end

  context 'for groups' do
    let(:groups) { lockfile_hash['groups'] }

    it 'should have default' do
      groups['default'].should eql expected_groups['default']
    end

    it 'should match development' do
      groups['development'].should eql expected_groups['development']
    end

    it 'should match test' do
      groups['test'].should eql expected_groups['test']
    end
  end
end
