require 'rubygems'
require 'lib/lock_jar'
require 'naether'

describe LockJar do
  context "Module" do
    it "should create a lock file" do
      File.delete( 'tmp/Jarfile.lock' ) if File.exists?( 'tmp/Jarfile.lock' )
      Dir.mkdir( 'tmp' ) unless File.exists?( 'tmp' )
      
      LockJar.lock( "spec/Jarfile", :jarfile => 'tmp/Jarfile.lock', :local_repo => 'tmp/test-repo' )
      File.exists?( 'tmp/Jarfile.lock' ).should be_true
    end
    
    it "should load jars" do
      if Naether.platform == 'java'
        lambda { include_class 'org.apache.mina.core.IoUtil' }.should raise_error
      else
        lambda { Rjb::import('org.apache.mina.core.IoUtil') }.should raise_error
      end
      jars = LockJar.load( 'tmp/Jarfile.lock' )
      
      jars.should eql( [File.expand_path("tmp/test-repo/org/apache/mina/mina-core/2.0.4/mina-core-2.0.4.jar"), 
        File.expand_path("tmp/test-repo/org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar")] )
        
      if Naether.platform == 'java'
        lambda { include_class 'org.apache.mina.core.IoUtil' }.should_not raise_error
      else
        lambda { Rjb::import('org.apache.mina.core.IoUtil') }.should_not raise_error
      end
    end
  end
end