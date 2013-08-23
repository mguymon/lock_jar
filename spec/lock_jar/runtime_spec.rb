require 'spec_helper'
require 'lock_jar/runtime'

describe LockJar::Runtime do
  context "Singleton" do
    it "should set local repo" do
      LockJar::Runtime.instance.load( nil, [], :resolve => true, :local_repo => TEST_REPO ) do
        jar 'junit:junit:4.10'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql TEST_REPO
      
      LockJar::Runtime.instance.load( nil, [], :local_repo => PARAM_CONFIG ) do
        local 'dsl_config'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql PARAM_CONFIG
    
      LockJar::Runtime.instance.load( nil ) do
        local DSL_CONFIG
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql DSL_CONFIG
    end
  end
end
