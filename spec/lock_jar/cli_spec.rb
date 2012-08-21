require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
require 'lock_jar/cli'

describe LockJar::CLI do
  describe "#process" do
    it "should lock a Jarfile" do
      Dir.chdir( 'spec' ) 
      LockJar::CLI.process( ['lock'] )
      
      File.exists?('Jarfile.lock').should be_true
      
      File.delete( 'Jarfile.lock' ) if File.exists?('Jarfile.lock')
      
      Dir.chdir( '../' ) 
    end
  end
end