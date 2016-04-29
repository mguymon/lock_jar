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

require 'yaml'
require 'singleton'
require 'lock_jar/config'
require 'lock_jar/resolver'
require 'lock_jar/registry'
require 'lock_jar/domain/dsl'
require 'lock_jar/domain/jarfile_dsl'
require 'lock_jar/domain/lockfile'
require 'lock_jar/runtime/load'
require 'lock_jar/runtime/lock'
require 'lock_jar/runtime/list'
require 'lock_jar/runtime/install'

module LockJar
  #
  class Runtime
    include Singleton
    include Load
    include List
    include Install

    attr_reader :current_resolver, :config

    def initialize
      @config = Config.load_config_file
      @current_resolver = nil
    end

    def lock(jarfile_or_dsl, opts = {}, &blk)
      Lock.new(self).lock(jarfile_or_dsl, opts, &blk)
    end

    def opts
      current_resolver.opts if current_resolver
    end

    def resolver(opts = {})
      # XXX: Caches the resolver by the options. Passing in nil opts will replay
      #      from the cache. This need to change.
      if !opts.nil?
        opts[:local_repo] = File.expand_path(opts[:local_repo]) if opts[:local_repo]
      elsif @current_resolver
        opts = @current_resolver.opts
      else
        opts = {}
      end

      if @current_resolver.nil? || opts != @current_resolver.opts
        @current_resolver = LockJar::Resolver.new(config, opts)
      end

      @current_resolver
    end

    def reset!
      @current_resolver = nil
    end

    private

    def lockfile_dependencies(lockfile, groups, with_locals = true)
      dependencies = []

      groups.each do |group|
        next unless lockfile.groups[group.to_s]
        dependencies += yield lockfile.groups[group.to_s]

        if with_locals
          locals = lockfile.groups[group.to_s]['locals']
          dependencies += locals if locals
        end
      end

      dependencies
    end

    def dsl_dependencies(dsl, groups, with_locals = true)
      dependencies = []

      groups.each do |group|
        dependencies += dsl.artifacts[group.to_s] if dsl.artifacts[group.to_s]
      end

      unless with_locals
        dependencies.select! { |dep| !dep.is_a? LockJar::Domain::Local }
      end

      dependencies
    end
  end
end
