source 'https://rubygems.org'

# Specify your gem's dependencies in lock_jar.gemspec
gemspec

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'jarfile_gem', path: 'spec/fixtures/jarfile_gem'
end

group :development do
  gem 'pry'
  gem 'yard'
  gem 'rubocop', '~> 0.36.0'
end
