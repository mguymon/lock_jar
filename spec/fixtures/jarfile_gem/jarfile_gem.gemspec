# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jarfile_gem/version'

Gem::Specification.new do |spec|
  spec.name          = "jarfile_gem"
  spec.version       = JarfileGem::VERSION
  spec.authors       = ["Michael Guymon"]
  spec.email         = ["michael@tobedevoured.com"]
  spec.summary       = %q{a short summary.}
  spec.description   = %q{a longer description.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
