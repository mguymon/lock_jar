require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe LockJar::Dsl do
  context "Instance" do
    it "should load a Jarfile" do
      jarfile = LockJar::Dsl.evaluate( "spec/Jarfile" )
      
      jarfile.local_repository.should eql '~/.m2/repository'
      jarfile.notations.should eql( {
        "compile"=>["org.apache.mina:mina-core:2.0.4", "spec/pom.xml"], 
        "runtime"=>["spec/pom.xml", "com.typesafe:config:jar:0.5.0"], 
        "test"=>["spec/pom.xml", "junit:junit:jar:4.10"]}  )
      jarfile.repositories.should eql( ['http://mirrors.ibiblio.org/pub/mirrors/maven2'] )
    end
    
    it "should load a block" do
      block = LockJar::Dsl.evaluate  do
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
      lambda { LockJar::Dsl.evaluate }.should raise_error
    end
    
    it "should merge dsl" do
      block1 = LockJar::Dsl.evaluate  do
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
      
      block2 = LockJar::Dsl.evaluate  do
        repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
        repository 'http://new-repo'
        
        jar "org.apache.mina:mina-core:2.0.4"
        jar "compile-jar"
            
        scope 'runtime' do
            jar 'runtime-jar'
            pom 'runtime-pom'
        end
        
        scope 'test' do
            jar 'test-jar'
            pom 'test-pom'
        end
      end
      
      dsl = block1.merge( block2 )
      
      dsl.notations.should eql( {"compile"=>["org.apache.mina:mina-core:2.0.4", "spec/pom.xml", "compile-jar"], "runtime"=>["spec/pom.xml", "org.apache.tomcat:servlet-api:jar:6.0.35", "runtime-jar", "runtime-pom"], "test"=>["spec/pom.xml", "junit:junit:jar:4.10", "test-jar", "test-pom"]}  )
      dsl.repositories.should eql( ["http://repository.jboss.org/nexus/content/groups/public-jboss", 'http://new-repo'] )
            
    end
  end
end