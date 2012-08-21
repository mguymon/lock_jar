require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
require 'lock_jar/cli'

describe LockJar::CLI do
  describe "#process" do
    it "should lock a Jarfile" do
      LockJar::CLI.process( 'lock' )
    end
  end
end