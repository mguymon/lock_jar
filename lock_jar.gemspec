# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'lock_jar/version'

Gem::Specification.new do |s|
  s.name = 'lock_jar'
  s.version = LockJar::VERSION
  s.authors = ['Michael Guymon']
  s.date = '2014-03-06'
  s.description = 'Manage Jar files for Ruby. In the spirit of Bundler, a Jarfile is used to generate a Jarfile.lock that contains all the resolved jar dependencies for scopes runtime, compile, and test. The Jarfile.lock can be used to populate the classpath'
  s.email = 'michael@tobedevoured.com'
  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.extra_rdoc_files = %w(LICENSE README.md)
  s.homepage = 'http://github.com/mguymon/lock_jar'
  s.licenses = %w(Apache)
  s.require_paths = %w(lib)
  s.summary = 'Manage Jar files for Ruby'

  s.add_dependency(%q<naether>, ['~> 0.14.0'])
  s.add_dependency(%q<thor>, ['>= 0.18.1'])
end
