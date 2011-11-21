require 'rubygems'
require 'lib/accelr'
require 'fileutils'
require 'naether'

describe Accelr do
  context "Instance" do
    it "should bootstrap naether" do
      FileUtils.mkdir_p( 'tmp/test-repo' )
      accelr = Accelr.new( 'tmp/test-repo' )
      
      deps = Naether::Bootstrap.check_local_repo_for_deps( 'tmp/test-repo' )
      deps[:missing].should eql([])
      deps[:exists].each do |dep|
        dep.values[0].should match /.+#{File::SEPARATOR}tmp#{File::SEPARATOR}test-repo#{File::SEPARATOR}.+/
      end
    end
  end
end