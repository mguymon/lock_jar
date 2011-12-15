require 'rubygems'
require 'lib/lock_jar/dsl'

describe LockJar::Dsl do
  context "Instance" do
    it "load a Jarfile" do
      jarfile = LockJar::Dsl.evaluate( "spec/Jarfile" )
      
      jarfile.notations.should eql( ["org.apache.mina:mina-core:2.0.4"] )
      jarfile.repositories.should eql( ["http://repository.jboss.org/nexus/content/groups/public-jboss"] )
    end
  end
end