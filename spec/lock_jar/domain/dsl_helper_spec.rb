require File.expand_path(File.join(File.dirname(__FILE__),'../../spec_helper'))

require 'lock_jar/domain/dsl_helper'

describe LockJar::Domain::DslHelper do
    
    it "should merge dsl" do
      block1 = LockJar::Domain::Dsl.evaluate  do
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
      
      block2 = LockJar::Domain::Dsl.evaluate  do
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
      
      dsl = LockJar::Domain::DslHelper.merge( block1, block2 )
      
      dsl.notations.should eql( {"compile"=>["org.apache.mina:mina-core:2.0.4", "spec/pom.xml", "compile-jar"], "runtime"=>["spec/pom.xml", "org.apache.tomcat:servlet-api:jar:6.0.35", "runtime-jar", "runtime-pom"], "test"=>["spec/pom.xml", "junit:junit:jar:4.10", "test-jar", "test-pom"]}  )
      dsl.repositories.should eql( ["http://repository.jboss.org/nexus/content/groups/public-jboss", 'http://new-repo'] )
            
    end
end