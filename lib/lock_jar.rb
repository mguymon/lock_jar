# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements. See the NOTICE file distributed with this
# work for additional information regarding copyright ownership. The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

require "yaml"
require 'rubygems'
require 'lock_jar/resolver'
require 'lock_jar/dsl'
require 'lock_jar/runtime'

module LockJar
  
  # Lock a Jarfile and generate a Jarfile.lock
  #
  # Accepts path to the jarfile and hash of options to configure LockJar
  def self.lock( jarfile = 'Jarfile', opts = {} )
    Runtime.new( opts ).lock( jarfile, opts )
  end
  
  # List jars for an array of scope in a lockfile
  #
  # Accepts path to the lockfile, array of scopes, and hash of options to configure LockJar
  def self.list( *args, &blk )
      lockfile = nil
      opts = {}
      scopes = ['compile', 'runtime']
        
      args.each do |arg|
        if arg.is_a?(Hash)
          opts.merge!( arg )
        elsif arg.is_a?( String )
          lockfile = arg
        elsif arg.is_a?( Array )
          scopes = arg
        end
      end
      
      # default to Jarfile.lock
      if blk.nil? && lockfile.nil?
        lockfile = 'Jarfile.lock'
      end
      
      Runtime.new( opts ).list( lockfile, scopes, &blk )
  end
    
  # Load jars for an array of scopes in a lockfile. Defaults lockfile to Jarfile.lock
  #
  # Accepts a path to the lockfile, array scopes, and hash of options to configure LockJar. A
  # block of LockJar::Dsl can be set.
  def self.load( *args, &blk )
      lockfile = nil
      opts = {}
      scopes = ['compile', 'runtime']
        
      args.each do |arg|
        if arg.is_a?(Hash)
          opts.merge!( arg )
        elsif arg.is_a?( String )
          lockfile = arg
        elsif arg.is_a?( Array )
          scopes = arg
        end
      end
      
      # default to Jarfile.lock
      if blk.nil? && lockfile.nil?
        lockfile = 'Jarfile.lock'
      end
      
      Runtime.new( opts ).load( lockfile, scopes, &blk )
  end
 
end