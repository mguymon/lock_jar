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
  config.order = 'default'
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end