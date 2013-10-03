require 'spec_helper'
require 'lock_jar/domain/artifact'

describe LockJar::Domain::Dsl do
  context "Instance" do
    it "should load a Jarfile" do
      jarfile = LockJar::Domain::Dsl.create( "spec/Jarfile" )
      
      jarfile.local_repository.should eql '~/.m2/repository'
      jarfile.artifacts["default"][0].should == LockJar::Domain::Artifact::Jar.new("org.apache.mina:mina-core:2.0.4")
      jarfile.artifacts["default"][1].path.should eql "spec/pom.xml"
      jarfile.artifacts["default"][2].should be_nil
      
      jarfile.artifacts["development"][0].should == LockJar::Domain::Artifact::Jar.new("com.typesafe:config:jar:0.5.0")
      jarfile.artifacts["development"][1].should be_nil
      
      jarfile.artifacts["test"][0].should == LockJar::Domain::Artifact::Jar.new("junit:junit:jar:4.10")
      jarfile.artifacts["test"][1].should be_nil
      
      jarfile.remote_repositories.should eql( ['http://mirrors.ibiblio.org/pub/mirrors/maven2'] )
    end
    
    it "should load a block" do
      block = LockJar::Domain::Dsl.create  do
        local_repo '~/.m2'
        repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
        
        jar "org.apache.mina:mina-core:2.0.4"
        pom 'spec/pom.xml' do

        end
            
        group 'pirate' do
            jar 'org.apache.tomcat:servlet-api:jar:6.0.35'
        end
        
        group 'test' do
            jar 'junit:junit:jar:4.10'
        end

      end

      
      block.local_repository.should eql '~/.m2'
      block.artifacts.should == {
        "default" => [LockJar::Domain::Artifact::Jar.new("org.apache.mina:mina-core:2.0.4"), LockJar::Domain::Artifact::Pom.new("spec/pom.xml")],
        "pirate" => [LockJar::Domain::Artifact::Jar.new("org.apache.tomcat:servlet-api:jar:6.0.35")],
        "test" => [LockJar::Domain::Artifact::Jar.new("junit:junit:jar:4.10")]
      }
      block.remote_repositories.should eql( ["http://repository.jboss.org/nexus/content/groups/public-jboss"] )
      block.poms.first.should_not be_nil
    end
    
    it "should raise an error without arguments" do
      lambda { LockJar::Domain::Dsl.create }.should raise_error
    end
    
  end
end
