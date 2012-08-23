require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
require 'lock_jar/cli'

describe LockJar::CLI do
  describe "#process" do
    it "should lock a Jarfile" do
      
      File.delete( 'Jarfile.lock' ) if File.exists?('spec/Jarfile.lock')
      
      LockJar::CLI.process( ['lock[spec/Jarfile]'] )
      
      File.exists?('Jarfile.lock').should be_true
      
      File.delete( 'Jarfile.lock' ) if File.exists?('spec/Jarfile.lock')
      
    end
    
    it "should list jars in Jarfile.lock" do
      LockJar::CLI.process( ['lock[spec/Jarfile]', 'list'] )
      
      LockJar::CLI.output.should eql "[\"org.apache.mina:mina-core:jar:2.0.4\", \"org.slf4j:slf4j-api:jar:1.6.1\", \"com.slackworks:modelcitizen:jar:0.2.2\", \"commons-lang:commons-lang:jar:2.6\", \"commons-beanutils:commons-beanutils:jar:1.8.3\", \"commons-logging:commons-logging:jar:1.1.1\", \"ch.qos.logback:logback-classic:jar:0.9.24\", \"ch.qos.logback:logback-core:jar:0.9.24\", \"com.metapossum:metapossum-scanner:jar:1.0\", \"commons-io:commons-io:jar:1.4\", \"junit:junit:jar:4.7\", \"org.apache.tomcat:servlet-api:jar:6.0.35\"]"
    end
  end
  
end