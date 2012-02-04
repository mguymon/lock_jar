require "yaml"
require 'rubygems'
require 'lib/lock_jar/resolver'
require 'lib/lock_jar/dsl'
require 'lib/lock_jar/runtime'

module LockJar
  
  def self.lock( jarfile, opts = {} )
    Runtime.new( opts ).lock( jarfile, opts )
  end
  
  def self.list( jarfile_lock, scopes = ['compile', 'runtime'], opts = {} )
      Runtime.new( opts ).list( jarfile_lock, scopes )
  end
    
  def self.load( jarfile_lock, scopes = ['compile', 'runtime'], opts = {} )
      Runtime.new( opts ).load( jarfile_lock, scopes )
  end

end