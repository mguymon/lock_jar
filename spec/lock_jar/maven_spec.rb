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
      LockJar::Maven.install( "maven_spec:install:7", "spec/pom.xml", nil, :local_repo => TEST_REPO )
      
      File.exists?( "#{TEMP_DIR}/test-repo/maven_spec/install/7/install-7.pom" ).should be_true
    end

    it "should invoke the compile goal for the maven project" do
      expect( LockJar::Maven.invoke( 'spec/pom.xml', 'compile', :local_repo => TEST_REPO).exitCode ).to eql 0
    end

    it "should make uberjar" do
      LockJar::Maven.uberjar 'spec/Jarfile', :destination_dir => "#{TEMP_DIR}", :assembly_dir => "#{TEMP_DIR}/assembly", :local_repo => TEST_REPO
      expect(File.exists?("#{TEMP_DIR}/assembly/META-INF/MANIFEST.MF")).to be_true
      expect(File.exists?("#{TEMP_DIR}/assembly/dependencies.yml")).to be_true
      expect(File.exists?("#{TEMP_DIR}/assembly/dependencies.md5")).to be_true
      expect(File.exists?("#{TEMP_DIR}/assembly/ch")).to be_true
      expect(File.exists?("#{TEMP_DIR}/assembly/com")).to be_true
      expect(File.exists?("#{TEMP_DIR}/assembly/junit")).to be_true
      expect(File.exists?("#{TEMP_DIR}/assembly/org")).to be_true

      expect(File.exists?("#{TEMP_DIR}/uberjar.jar")).to be_true
      File.size("#{TEMP_DIR}/uberjar.jar").should > 0
    end
  end
end
