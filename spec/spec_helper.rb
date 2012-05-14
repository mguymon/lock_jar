$:.unshift File.expand_path('.')
$:.unshift File.expand_path(File.join('..', File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join('../lib', File.dirname(__FILE__)))

require 'rubygems'
require 'rspec'
require 'lib/lock_jar'

RSpec.configure do |config|
  
end