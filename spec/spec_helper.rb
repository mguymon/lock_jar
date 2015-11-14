$LOAD_PATH.unshift File.expand_path('.')
$LOAD_PATH.unshift File.expand_path(File.join('..', File.dirname(__FILE__)))
$LOAD_PATH.unshift File.expand_path(File.join('..', File.dirname(__FILE__), 'lib'))

require 'rspec'
require 'lock_jar'
require 'lock_jar/cli'
require 'stringio'
require 'fileutils'
require 'lock_jar/logging'
require 'pry'
require 'codeclimate-test-reporter'

# coverage
CodeClimate::TestReporter.start

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('.') + '/spec/support/**/*.rb'].each { |f| require f }

LockJar::Logging.verbose!

# rubocop:disable Style/GlobalVars
def mock_terminal
  @input = StringIO.new
  @output = StringIO.new
  $terminal = HighLine.new @input, @output
end
# rubocop:enable Style/GlobalVars

TEMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '.spec-tmp'))
TEST_REPO = File.expand_path(File.join(TEMP_DIR, 'test-repo'))
PARAM_CONFIG = File.expand_path(File.join(TEMP_DIR, 'param_config'))
DSL_CONFIG = File.expand_path(File.join(TEMP_DIR, 'dsl_config'))

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
