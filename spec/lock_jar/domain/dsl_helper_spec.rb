require 'spec_helper'

require 'lock_jar/domain/dsl_helper'

describe LockJar::Domain::DslHelper do
    
    it "should merge dsl" do
      block1 = LockJar::Domain::Dsl.create  do
        repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
        
        jar "org.apache.mina:mina-core:2.0.4"
        pom 'spec/pom.xml'
            
        group 'runtime' do
            jar 'org.apache.tomcat:servlet-api:jar:6.0.35'
        end
        
        group 'test' do
            jar 'junit:junit:jar:4.10'
        end
      end
      
      block2 = LockJar::Domain::Dsl.create  do
        repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
        repository 'http://new-repo'
        
        jar "org.apache.mina:mina-core:2.0.4"
        jar "compile-jar"
            
        group 'runtime' do
            jar 'runtime-jar'
            pom 'runtime-pom.xml'
        end
        
        group 'test' do
            jar 'test-jar'
            pom 'test-pom.xml'
        end
      end
      
      dsl = LockJar::Domain::DslHelper.merge( block1, block2 )
      
      dsl.artifacts['default'].should =~ [LockJar::Domain::Artifact::Jar.new("org.apache.mina:mina-core:2.0.4"), LockJar::Domain::Artifact::Pom.new("spec/pom.xml",["runtime", "compile"]), LockJar::Domain::Artifact::Jar.new("compile-jar")]
      
      #  "runtime" => [LockJar::Domain::Jar.new("org.apache.tomcat:servlet-api:jar:6.0.35"), LockJar::Domain::Jar.new("runtime-jar"), LockJar::Domain::Pom.new("runtime-pom.xml")], 
      #  "test" => [LockJar::Domain::Jar.new("junit:junit:jar:4.10"), LockJar::Domain::Jar.new("test-jar"), LockJar::Domain::Pom.new("test-pom.xml")]
      
      
      dsl.remote_repositories.should eql( ["http://repository.jboss.org/nexus/content/groups/public-jboss", 'http://new-repo'] )
            
    end
end
