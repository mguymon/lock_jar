require 'spec_helper'
require 'lock_jar/resolver'
require 'fileutils'
require 'naether'

describe LockJar::Resolver do
  context "Instance" do
    before(:each) do
      FileUtils.mkdir_p( "#{TEMP_DIR}/test-repo" )
      @resolver = LockJar::Resolver.new( :local_repo => "#{TEMP_DIR}/test-repo" )
    end
    
    it "should bootstrap naether" do
      deps = Naether::Bootstrap.check_local_repo_for_deps( "#{TEMP_DIR}/test-repo" )
      deps[:missing].should eql([])
      deps[:exists].each do |dep|
        dep.values[0].should match /#{TEMP_DIR}#{File::SEPARATOR}test-repo#{File::SEPARATOR}.+/
      end
    end
    
    it "should return local paths for notations" do
      @resolver.to_local_paths( ["junit:junit:jar:4.10"] ).should 
      eql( [File.expand_path("#{TEMP_DIR}/test-repo/junit/junit/4.10/junit-4.10.jar")] )
    end
  end
end
