require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
require 'lib/lock_jar/cli'

describe LockJar::CLI do
  before :each do
    $stderr = StringIO.new
    mock_terminal
  end
  
  it "should have commands" do
    LockJar::CLI.commands.keys.should eql( ["help", "install", "list", "lock"] )
  end
  
end