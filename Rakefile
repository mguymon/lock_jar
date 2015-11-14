# encoding: utf-8

require 'bundler'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require "bundler/gem_tasks"
require 'rdoc/task'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end


RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lockjar #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task default: [:spec, :rubocop]
