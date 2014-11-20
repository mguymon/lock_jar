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
require 'lock_jar/runtime'
require 'lock_jar/version'
require 'lock_jar/domain/lockfile'
require 'lock_jar/domain/dsl'

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
    lockfile, groups, opts = extract_args :lockfile, args, &blk
    Runtime.instance.install( lockfile, groups, opts, &blk )
  end


  # Lists all dependencies as notations for groups from the Jarfile.lock. Depending on the type of arg, a different configuration is set.
  #
  # * An arg of a String will set the Jarfile.lock, e.g. 'Better.lock'.  Default lock file is *Jarfile.lock*.
  # * An arg of an Array will set the groups, e.g. ['development','test'].  Defaults group is *default*
  # * An arg of a Hash will set the options, e.g. { :local_repo => 'path' }
  #   * :local_repo [String] sets the local repo path
  #   * :local_paths [Boolean] to true converts the notations to paths to jars in the local repo path
  #   * :resolve [Boolean] to true will make transitive dependences resolve before loading to classpath
  #
  # A block can be passed in, overriding values from a Jarfile.lock.
  #
  # @return [Array] of jar and mapped path
  def self.list( *args, &blk )
    lockfile, groups, opts = extract_args :lockfile, args, &blk
    Runtime.instance.list( lockfile, groups, opts, &blk )
  end

  # LockJar.load(*args): Loads all dependencies to the classpath for groups from the Jarfile.lock. Depending on the type of arg, a different configuration is set.
  # * An arg of a String will set the Jarfile.lock, e.g. 'Better.lock'. Default lock file is *Jarfile.lock*.
  # * An arg of an Array will set the groups, e.g. ['development','test'].Defaults group is *default*.
  # * An arg of a Hash will set the options, e.g. { :local_repo => 'path' }
  #    * :local_repo sets the local repo path
  #    * :resolve to true will make transitive dependences resolve before loading to classpath
  #
  # A block can be passed in, overriding values from a Jarfile.lock.
  #
  # @return [Array] of absolute paths of jars and mapped paths loaded into claspath
  def self.load( *args, &blk )
    lockfile, groups, opts = extract_args :lockfile, args, &blk
    Runtime.instance.load( lockfile, groups, opts, &blk )
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
    jarfile, groups, opts = extract_args :jarfile, args, &blk
    Runtime.instance.lock( jarfile, opts, &blk )
  end

  #
  # Read a Jafile.lock and convert it to a LockJar::Domain::Lockfile
  #
  # @param [String] lockfile path to lockfile
  # @return [Hash] Lock Data
  def self.read( lockfile )
    LockJar::Domain::Lockfile.read( lockfile )
  end

  # Add a Jarfile to be included when LockJar.lock_registered_jarfiles is called.
  #
  # @param [String] jarfile path to register
  # @return [Array] All registered jarfiles
  def self.register_jarfile( jarfile )
    fail "Jarfile not found: #{ jarfile }" unless File.exists? jarfile
    registered_jarfiles << jarfile
  end

  def self.reset_registered_jarfiles
    @@registered_jarfiles = []
  end

  def self.registered_jarfiles
    @@registered_jarfiles ||= []
  end

  # Lock the registered Jarfiles and generate a Jarfile.lock.
  #
  # Options and groups are passed through to the LockJar.lock method, but
  # if a Jarfile is specified, it will be ignored. Use LockJar.register_jarfile
  # to add dependencies.
  #
  # A block can be passed in, overriding values from the Jarfiles.
  #
  # @return [Hash] Lock data
  def self.lock_registered_jarfiles( *args, &blk )
    jarfiles = registered_jarfiles
    return if jarfiles.empty?
    instances = jarfiles.map do |jarfile|
      LockJar::Domain::JarfileDsl.create jarfile
    end
    combined = instances.reduce do |result, inst|
      LockJar::Domain::DslHelper.merge result, inst
    end
    args = args.reject { |arg| arg.is_a? String }
    lock combined, *args, &blk
  end

  private

  def self.extract_args(type, args, &blk )
    lockfile_or_path = nil
    opts = {}
    groups = ['default']
    args.each do |arg|
      case arg
      when Hash
        opts.merge!( arg )
      when String
        lockfile_or_path = arg
      when LockJar::Domain::Lockfile
        lockfile_or_path = arg if type == :lockfile
      when LockJar::Domain::Dsl
        lockfile_or_path = arg if type == :jarfile
      when Array
        groups = arg
      end
    end
    if blk.nil? && lockfile_or_path.nil?
      if type == :lockfile
        lockfile_or_path = 'Jarfile.lock'
      elsif type == :jarfile
        lockfile_or_path = 'Jarfile'
      end
    end
    [lockfile_or_path, groups, opts]
  end
end

