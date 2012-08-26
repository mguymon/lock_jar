require 'rubygems'
require 'commander/import'
require 'lock_jar'
require 'lock_jar/version'
  
module LockJar::CLI

  # :name is optional, otherwise uses the basename of this executable
  program :name, 'Lock Jar'
  program :version, LockJar::VERSION
  program :description, 'LockJar manages Java Jars for Ruby'
  
  command :install do |c|
    c.syntax = 'lockjar install'
    c.description = 'Install Jars from a Jarfile.lock'
    c.option '--lockfile STRING', String, 'Path to Jarfile.lock, defaults to Jarfile.lock'
    c.option '--scopes ARRAY', Array, "Scopes to install from Jarfile.lock, defaults to 'compile, runtime'"
    c.action do |args, options|
      options.default :lockfile => 'Jarfile.lock', :scopes => ['compile', 'runtime']
      puts "Installing Jars from #{options.lockfile} for #{options.scopes.inspect}"
      LockJar.install( options.lockfile, options.scopes )
    end
  end
  
  command :list do |c|
    c.syntax = 'lockjar list'
    c.description = 'List Jars from a Jarfile.lock'
    c.option '--lockfile STRING', String, 'Path to Jarfile.lock, defaults to Jarfile.lock'
    c.option '--scopes ARRAY', Array, "Scopes to install from Jarfile.lock, defaults to 'compile, runtime'"
    c.action do |args, options|
      options.default :lockfile => 'Jarfile.lock', :scopes => ['compile', 'runtime']
      puts "Listing Jars from #{options.lockfile} for #{options.scopes.inspect}"
      puts LockJar.list( options.lockfile, options.scopes ).inspect
    end
  end
  
  command :lock do |c|
    c.syntax = 'lockjar lock'
    c.description = 'Lock Jars in a Jarfile'
    c.option '--jarfile STRING', String, 'Path to Jarfile, defaults to Jarfile'
    c.action do |args, options|
      options.default :lockfile => 'Jarfile.lock', :scopes => ['compile', 'runtime']
      puts "Locking #{options.lockfile}"
      LockJar.lock( options.lockfile, options.scopes )
    end
  end  
end
