require 'rubygems'
require 'lib/lock_jar/resolver'
require 'fileutils'
require 'naether'

describe LockJar::Resolver do
  context "Instance" do
    before(:each) do
      FileUtils.mkdir_p( 'tmp/test-repo' )
      @resolver = LockJar::Resolver.new( :local_repo => 'tmp/test-repo' )
    end
    
    it "should bootstrap naether" do
      deps = Naether::Bootstrap.check_local_repo_for_deps( 'tmp/test-repo' )
      deps[:missing].should eql([])
      deps[:exists].each do |dep|
        dep.values[0].should match /.+#{File::SEPARATOR}tmp#{File::SEPARATOR}test-repo#{File::SEPARATOR}.+/
      end
    end
    
    it "should return local paths for notations" do
      @resolver.to_local_paths( ["org.modeshape:modeshape-common:2.3.0.Final"] ).should 
        eql( [File.expand_path("tmp/test-repo/org/modeshape/modeshape-common/2.3.0.Final/modeshape-common-2.3.0.Final.jar")] )
    end
  end
end