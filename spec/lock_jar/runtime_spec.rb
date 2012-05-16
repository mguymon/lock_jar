require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
require 'lib/lock_jar/runtime'

describe LockJar::Runtime do
  context "Singleton" do
    it "should set local repo" do
      LockJar::Runtime.instance.load( nil, [], :resolve => true, :local_repo => 'tmp/test-repo' ) do 
        jar 'junit:junit:4.10'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql File.expand_path('tmp/test-repo') 
      
      LockJar::Runtime.instance.load( nil, [], :local_repo => 'tmp/param_config' ) do 
        local 'dsl_config'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql File.expand_path('tmp/param_config')
    
      LockJar::Runtime.instance.load( nil ) do 
        local 'tmp/dsl_config'
      end
      
      LockJar::Runtime.instance.current_resolver.naether.local_repo_path.should eql File.expand_path('tmp/dsl_config')
    
    end
  end
end