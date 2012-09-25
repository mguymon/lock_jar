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
require 'lock_jar/version'
require 'lock_jar/rubygems'

#
# LockJar manages Java Jars for Ruby.
#
# @author Michael Guymon
#
module LockJar
  
  #
  # Override LockJar configuration
  #
  def self.config( opts )
    Runtime.instance.resolver( opts )
  end
  
  def self.install( *args, &blk )
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
    
    Runtime.instance.install( lockfile, scopes, opts, &blk )
  end
  
  
  # Lists all dependencies as notations for scopes from the Jarfile.lock. Depending on the type of arg, a different configuration is set.
  #
  # * An arg of a String will set the Jarfile.lock, e.g. 'Better.lock'.  Default lock file is *Jarfile.lock*.
  # * An arg of an Array will set the scopes, e.g. ['compile','test'].  Defaults scopes are *compile* and *runtime*
  # * An arg of a Hash will set the options, e.g. { :local_repo => 'path' }
  #   * :local_repo sets the local repo path
  #   * :local_paths converts the notations to paths to jars in the local repo path
  #   * :resolve to true will make transitive dependences resolve before loading to classpath
  # 
  # A block can be passed in, overriding values from a Jarfile.lock.
  #
  # @return [Array] of jar and mapped path
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
      
      Runtime.instance.list( lockfile, scopes, opts, &blk )
  end
    
  # LockJar.load(*args): Loads all dependencies to the classpath for scopes from the Jarfile.lock. Depending on the type of arg, a different configuration is set.
  # * An arg of a String will set the Jarfile.lock, e.g. 'Better.lock'. Default lock file is *Jarfile.lock*.
  # * An arg of an Array will set the scopes, e.g. ['compile','test'].Defaults scopes are *compile* and *runtime*.
  # * An arg of a Hash will set the options, e.g. { :local_repo => 'path' }
  #    * :local_repo sets the local repo path
  #    * :resolve to true will make transitive dependences resolve before loading to classpath
  # 
  # A block can be passed in, overriding values from a Jarfile.lock.
  #
  # @return [Array] of absolute paths of jars and mapped paths loaded into claspath
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
      
      Runtime.instance.load( lockfile, scopes, opts, &blk )
  end
  
  # Lock a Jarfile and generate a Jarfile.lock. 
  #
  # LockJar.lock accepts an Array for parameters. Depending on the type of arg, a different configuration is set.
  #
  # * An arg of a String will set the Jarfile, e.g. 'Jarfile.different'. Default Jarfile is *Jarfile*.
  # * An arg of a Hash will set the options, e.g. { :local_repo => 'path' }
  #   * :download_artifacts if true, will download jars to local repo. Defaults to true.
  #   * :local_repo sets the local repo path
  #   * :lockfile sets the Jarfile.lock path. Default lockfile is *Jarfile.lock*.
  #
  # A block can be passed in, overriding values from a Jarfile.
  #
  # @return [Hash] Lock data
  def self.lock( *args, &blk )
    jarfile = nil
    opts = {}
      
    args.each do |arg|
      if arg.is_a?(Hash)
        opts.merge!( arg )
      elsif arg.is_a?( String ) || arg.is_a?( LockJar::Dsl )
        jarfile = arg
      end
    end
    
    # default to Jarfile
    if blk.nil? && jarfile.nil?
      jarfile = 'Jarfile'
    end
    
    Runtime.instance.lock( jarfile, opts, &blk )
  end
  
  #
  # Read a Jafile.lock and convert it to a Hash
  #
  # @param [String] lockfile path to lockfile
  # @return [Hash] Lock Data
  def self.read( lockfile )
    Runtime.instance.read_lockfile( lockfile )
  end
 
end

#include LockJar::Rubygems::Kernel
