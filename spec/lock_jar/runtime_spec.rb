require 'spec_helper'
require 'lock_jar/runtime'

describe LockJar::Runtime do
  describe '#load' do
    it 'should set local repo' do
      LockJar::Runtime.instance.load(nil, [], resolve: true, local_repo: TEST_REPO) do
        jar 'junit:junit:4.10'
      end

      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql TEST_REPO
    end

    it 'should use the local repo from the dsl' do
      LockJar::Runtime.instance.load(nil) do
        local_repo DSL_CONFIG
      end

      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql DSL_CONFIG
    end

    it 'should use the local repo from param' do
      LockJar::Runtime.instance.load(nil, [], local_repo: PARAM_CONFIG) do
        local_repo 'dsl_config'
      end

      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql PARAM_CONFIG
    end
  end
end
