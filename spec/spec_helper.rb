$:.unshift File.expand_path('.')
$:.unshift File.expand_path(File.join('..', File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join('..', File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'rspec'
require 'lock_jar'
require 'lock_jar/cli'
require 'stringio'
require 'fileutils'
require 'support/helper'

def mock_terminal
  @input = StringIO.new
  @output = StringIO.new
  $terminal = HighLine.new @input, @output
end

TEMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".spec-tmp"))
TEST_REPO = File.expand_path(File.join(TEMP_DIR, "test-repo"))
PARAM_CONFIG = File.expand_path(File.join(TEMP_DIR, "param_config"))
DSL_CONFIG = File.expand_path(File.join(TEMP_DIR, "dsl_config"))

RSpec.configure do |config|
  config.order = 'default'
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.before(:suite) do
    FileUtils.mkdir_p(DSL_CONFIG)
  end

  config.after(:suite) do
    FileUtils.rm_rf(PARAM_CONFIG)
    FileUtils.rm_rf(DSL_CONFIG)
  end
end
