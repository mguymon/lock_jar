# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lock_jar/bundler/version'

Gem::Specification.new do |spec|
  spec.name          = 'lock_jar_bundler'
  spec.version       = LockJar::Bundler::VERSION
  spec.authors       = ['Michael Guymon']
  spec.email         = %w(michael@tobedevoured)
  spec.summary       = 'Manage Jar files for Ruby'
  spec.description   = 'Manage Jar files for Ruby. In the spirit of Bundler, a Jarfile is used to generate a Jarfile.lock that contains all the resolved jar dependencies for scopes runtime, compile, and test. The Jarfile.lock can be used to populate the classpath'
  spec.homepage      = 'http://github.com/mguymon/lock_jar'
  spec.license       = 'Apache'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'lock_jar', '>= 0.8.0'
  spec.add_development 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
