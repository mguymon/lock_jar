$:.unshift File.expand_path('.')
$:.unshift File.expand_path(File.join('..', File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join('..', File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'rspec'
require 'lib/lock_jar'
require 'stringio'

def mock_terminal
  @input = StringIO.new
  @output = StringIO.new
  $terminal = HighLine.new @input, @output
end

RSpec.configure do |config|
  
end