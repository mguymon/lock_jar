require 'rubygems'
require 'lib/lock_jar/dsl'

describe LockJar::Dsl do
  context "Instance" do
    it "load a Jarfile" do
      jarfile = LockJar::Dsl.evaluate( "spec/Jarfile" )
      
      jarfile.notations.should eql( {"compile"=>["org.apache.mina:mina-core:2.0.4"], "runtime"=>["org.apache.tomcat:servlet-api:jar:6.0.35"], "test"=>["junit:junit:jar:4.10"]}  )
      jarfile.repositories.should eql( ["http://repository.jboss.org/nexus/content/groups/public-jboss"] )
    end
  end
end