# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'dummy_gem'
  spec.version       = 0.1
  spec.authors       = ['Michael Guymon']
  spec.email         = %w(michael@tobedevoured)
  spec.summary       = 'For testing LockJar Bundler support'
  spec.description   = 'For testing LockJar Bundler support'
  spec.homepage      = 'http://github.com/mguymon/lock_jar'
  spec.license       = 'Apache'

  spec.files         = []
  spec.executables   = []
  spec.test_files    = []
  spec.require_paths = ["lib"]

  spec.add_dependency 'json'
end
