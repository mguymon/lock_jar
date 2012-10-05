require File.expand_path(File.join(File.dirname(__FILE__),'../../spec_helper'))

describe LockJar::Domain::Dsl do
  context "Instance" do
    it "should load a Jarfile" do
      jarfile = LockJar::Domain::Dsl.evaluate( "spec/Jarfile" )
      
      jarfile.local_repository.should eql '~/.m2/repository'
      jarfile.notations.should eql( {
        "compile"=>["org.apache.mina:mina-core:2.0.4", "spec/pom.xml"], 
        "runtime"=>["spec/pom.xml", "com.typesafe:config:jar:0.5.0"], 
        "test"=>["spec/pom.xml", "junit:junit:jar:4.10"]}  )
      jarfile.repositories.should eql( ['http://mirrors.ibiblio.org/pub/mirrors/maven2'] )
    end
    
    it "should load a block" do
      block = LockJar::Domain::Dsl.evaluate  do
        local '~/.m2'
        repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
        
        jar "org.apache.mina:mina-core:2.0.4"
        pom 'spec/pom.xml'
            
        scope 'runtime' do
            jar 'org.apache.tomcat:servlet-api:jar:6.0.35'
        end
        
        scope 'test' do
            jar 'junit:junit:jar:4.10'
        end
      end
      
      block.local_repository.should eql '~/.m2'
      block.notations.should eql( {"compile"=>["org.apache.mina:mina-core:2.0.4", "spec/pom.xml"], "runtime"=>["spec/pom.xml", "org.apache.tomcat:servlet-api:jar:6.0.35"], "test"=>["spec/pom.xml", "junit:junit:jar:4.10"]}  )
      block.repositories.should eql( ["http://repository.jboss.org/nexus/content/groups/public-jboss"] )
          
    end
    
    it "should raise an error without arguments" do
      lambda { LockJar::Domain::Dsl.evaluate }.should raise_error
    end
    
  end
end