require 'rubygems'
require 'lib/lock_jar'
require 'naether'

describe LockJar do
  context "Module" do
    it "should create a lock file" do
      File.delete( 'tmp/Jarfile.lock' ) if File.exists?( 'tmp/Jarfile.lock' )
      Dir.mkdir( 'tmp' ) unless File.exists?( 'tmp' )
      
      lock_jar = LockJar.setup( :local_repo => 'tmp/test-repo' )
      lock_jar.lock( "spec/Jarfile", :jarfile => 'tmp/Jarfile.lock' )
      File.exists?( 'tmp/Jarfile.lock' ).should be_true
    end
    
    it "should load jars" do
      if Naether.platform == 'java'
        lambda { include_class 'org.apache.mina.core.IoUtil' }.should raise_error
      else
        lambda { Rjb::import('org.apache.mina.core.IoUtil') }.should raise_error
      end
      
      lock_jar = LockJar.setup( :local_repo => 'tmp/test-repo' )
      jars =  lock_jar.load( 'tmp/Jarfile.lock' )
      
      jars.should eql( [File.expand_path("tmp/test-repo/org/apache/mina/mina-core/2.0.4/mina-core-2.0.4.jar"), File.expand_path("tmp/test-repo/org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar"), File.expand_path("tmp/test-repo/com/slackworks/modelcitizen/0.2.2/modelcitizen-0.2.2.jar"), File.expand_path("tmp/test-repo/commons-lang/commons-lang/2.6/commons-lang-2.6.jar"), File.expand_path("tmp/test-repo/commons-beanutils/commons-beanutils/1.8.3/commons-beanutils-1.8.3.jar"), File.expand_path("tmp/test-repo/commons-logging/commons-logging/1.1.1/commons-logging-1.1.1.jar"), File.expand_path("tmp/test-repo/ch/qos/logback/logback-classic/0.9.24/logback-classic-0.9.24.jar"), File.expand_path("tmp/test-repo/ch/qos/logback/logback-core/0.9.24/logback-core-0.9.24.jar"), File.expand_path("tmp/test-repo/com/metapossum/metapossum-scanner/1.0/metapossum-scanner-1.0.jar"), File.expand_path("tmp/test-repo/commons-io/commons-io/1.4/commons-io-1.4.jar"), File.expand_path("tmp/test-repo/junit/junit/4.7/junit-4.7.jar"), File.expand_path("tmp/test-repo/org/apache/tomcat/servlet-api/6.0.35/servlet-api-6.0.35.jar")] )
        
      if Naether.platform == 'java'
        lambda { include_class 'org.apache.mina.core.IoUtil' }.should_not raise_error
      else
        lambda { Rjb::import('org.apache.mina.core.IoUtil') }.should_not raise_error
      end
    end
  end
end