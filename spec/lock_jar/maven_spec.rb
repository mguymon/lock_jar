require 'spec_helper'
require 'lock_jar'
require 'lock_jar/maven'
require 'naether'

describe LockJar::Maven do
  before do
    # Bootstrap Naether
    Naether::Bootstrap.bootstrap_local_repo
  end
  
  context "Class" do
    it "should get pom version" do
      LockJar::Maven.pom_version( "spec/pom.xml" ).should eql( "3" )
    end
    
    it "should install artifact" do
      LockJar::Maven.install( "maven_spec:install:7", "spec/pom.xml", nil, :local_repo => 'tmp/test-repo' )
      
      File.exists?( 'tmp/test-repo/maven_spec/install/7/install-7.pom' ).should be_true
    end
  end
end
