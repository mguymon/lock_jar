require 'spec/spec_helper'
require 'lib/lock_jar/runtime'

describe LockJar::Runtime do
  context "Singleton" do
    it "should set local repo" do
      LockJar::Runtime.instance.load( nil ) do 
        jar 'junit:junit:4.10'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql File.expand_path('~/.m2/repository')
      
      LockJar::Runtime.instance.load( nil, [], :local_repo => 'tmp/param_config' ) do 
        local 'dsl_config'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql 'tmp/param_config'
    
      LockJar::Runtime.instance.load( nil ) do 
        local 'tmp/dsl_config'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql 'tmp/dsl_config'
    
    end
  end
end