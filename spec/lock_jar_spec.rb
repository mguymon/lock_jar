require 'rubygems'
require 'lib/lock_jar'

describe LockJar do
  context "Module" do
    it "should create a lock file" do
      LockJar.lock( "spec/Jarfile" )
    end
  end
end