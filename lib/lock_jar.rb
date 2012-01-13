require "yaml"
require 'rubygems'
require 'lib/lock_jar/resolver'
require 'lib/lock_jar/dsl'
require 'lib/lock_jar/runtime'

module LockJar
  
  def self.setup( opts = {} )
    Runtime.new( opts )
  end

end