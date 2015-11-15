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
require 'lock_jar/resolver'
require 'lock_jar/registry'
require 'lock_jar/domain/dsl'
require 'lock_jar/domain/jarfile_dsl'
require 'lock_jar/domain/lockfile'

module LockJar
  #
  class Runtime
    include Singleton

    attr_reader :current_resolver

    def initialize
      @current_resolver = nil
    end

    def opts
      current_resolver.opts if current_resolver
    end

    def resolver(opts = {})
      # XXX: Caches the resolver by the options. Passing in nil opts will replay
      #      from the cache. This need to change.
      if !opts.nil?
        opts[:local_repo] = File.expand_path(opts[:local_repo]) if opts[:local_repo]
      else
        if @current_resolver
          opts = @current_resolver.opts
        else
          opts = {}
        end
      end

      if @current_resolver.nil? || opts != @current_resolver.opts
        @current_resolver = LockJar::Resolver.new(opts)
      end

      @current_resolver
    end

    def reset!
      @current_resolver = nil
    end

    def install(jarfile_lock, groups = ['default'], opts = {}, &blk)
      deps = list(jarfile_lock, groups, { with_locals: false }.merge(opts), &blk)

      lockfile = LockJar::Domain::Lockfile.read(jarfile_lock)
      if opts[:local_repo].nil? && lockfile.local_repository
        opts[:local_repo] = lockfile.local_repository
      end

      # Older Jarfile expected the defaul maven repo, but did not write
      # it to the lockfile
      resolver(opts).clear_remote_repositories if lockfile.version.to_f >= 0.11

      lockfile.remote_repositories.each do |repo|
        resolver(opts).add_remote_repository(repo)
      end

      files = resolver(opts).download(deps)

      files
    end

    def lock(jarfile_or_dsl, opts = {}, &blk)
      opts = { download: true }.merge(opts)

      jarfile = nil

      if jarfile_or_dsl
        if jarfile_or_dsl.is_a? LockJar::Domain::Dsl
          jarfile = jarfile_or_dsl
        else
          jarfile = LockJar::Domain::JarfileDsl.create(jarfile_or_dsl)
        end
      end

      unless blk.nil?
        dsl = LockJar::Domain::Dsl.create(&blk)
        if jarfile.nil?
          jarfile = dsl
        else
          jarfile = LockJar::Domain::DslMerger(jarfile, dsl).merge
        end
      end

      # If not set in opts, and is set in  dsl
      if opts[:local_repo].nil? && jarfile.local_repository
        opts[:local_repo] = jarfile.local_repository
      end

      lockfile = LockJar::Domain::Lockfile.new

      if jarfile.clear_repositories
        resolver(opts).clear_remote_repositories
      else
        repos = resolver(opts).remote_repositories
        lockfile.remote_repositories += repos.to_a if repos
      end

      jarfile.remote_repositories.each do |repo|
        resolver(opts).add_remote_repository(repo)
        lockfile.remote_repositories << repo
      end

      lockfile.local_repository = jarfile.local_repository unless jarfile.local_repository.nil?

      lockfile.maps = jarfile.maps if jarfile.maps.size > 0

      lockfile.excludes = jarfile.excludes if jarfile.excludes.size > 0

      artifacts = []
      jarfile.artifacts.each do |_, group_artifacts|
        artifacts += group_artifacts
      end

      lockfile.merged = jarfile.merged unless jarfile.merged.empty?

      unless artifacts.empty?
        resolver(opts).resolve(
          artifacts.select(&:resolvable?).map(&:to_dep),
          opts[:download] == true
        )

        jarfile.artifacts.each do |group_name, group_artifacts|
          group = { 'locals' => [], 'dependencies' => [], 'artifacts' => [] }

          group_artifacts.each do |artifact|
            artifact_data = {}

            if artifact.is_a? LockJar::Domain::Jar
              group['dependencies'] << artifact.notation
              g = resolver(opts).dependencies_graph[artifact.notation]
              artifact_data['transitive'] = g.to_hash if g

            elsif artifact.is_a? LockJar::Domain::Pom
              artifact_data['scopes'] = artifact.scopes

              # iterate each dependency in Pom to map transitive dependencies
              transitive = {}
              artifact.notations.each do |notation|
                transitive.merge!(notation => resolver(opts).dependencies_graph[notation])
              end
              artifact_data['transitive'] = transitive

            elsif artifact.is_a? LockJar::Domain::Local
              group['locals'] << artifact.path
            else
              fail("Unsupported artifact: #{artifact.inspect}")
            end

            # flatten the graph of nested hashes
            dep_merge = lambda do |graph|
              deps = graph.keys
              graph.values.each do |next_step|
                deps += dep_merge.call(next_step)
              end
              deps
            end

            next unless artifact_data['transitive']

            group['dependencies'] += dep_merge.call(artifact_data['transitive'])
            # xxX: set required_by ?
            group['artifacts'] << { artifact.to_urn => artifact_data }
          end

          lockfile.excludes.each do |exclude|
            group['dependencies'].delete_if { |dep| dep =~ /#{exclude}/ }
          end if lockfile.excludes

          group['dependencies'].sort!
          group.delete 'locals' if group['locals'].empty?

          lockfile.groups[group_name] = group
        end
      end

      lockfile.write(opts[:lockfile] || 'Jarfile.lock')

      lockfile
    end

    def list(lockfile_or_path, groups = ['default'], opts = {}, &blk)
      lockfile = nil
      dependencies = []
      maps = []
      with_locals = { with_locals: true }.merge(opts).delete(:with_locals)

      if lockfile_or_path
        if lockfile_or_path.is_a? LockJar::Domain::Lockfile
          lockfile = lockfile_or_path
        elsif lockfile_or_path
          lockfile = LockJar::Domain::Lockfile.read(lockfile_or_path)
        end

        dependencies = lockfile_dependencies(lockfile, groups, with_locals)
        maps = lockfile.maps
      end

      # Support limited DSL from block
      unless blk.nil?
        dsl = LockJar::Domain::Dsl.create(&blk)
        dependencies += dsl_dependencies(dsl, groups, with_locals).map(&:to_dep)
        maps = dsl.maps
      end

      if maps && maps.size > 0
        mapped_dependencies = []

        maps.each do |notation, replacements|
          dependencies.each do |dep|
            if dep =~ /#{notation}/
              replacements.each do |replacement|
                mapped_dependencies << replacement
              end
            else
              mapped_dependencies << dep
            end
          end
        end

        dependencies = mapped_dependencies
      end

      dependencies = resolver(opts).resolve(dependencies) if opts[:resolve]

      if opts[:local_paths]
        opts.delete(:local_paths) # remove list opts so resolver is not reset
        resolver(opts).to_local_paths(dependencies)

      else
        dependencies
      end
    end

    # Load paths from a lockfile or block. Paths are loaded once per lockfile.
    #
    # @param [String] lockfile_path the lockfile
    # @param [Array] groups to load into classpath
    # @param [Hash] opts
    # @param [Block] blk
    def load(lockfile_or_path, groups = ['default'], opts = {}, &blk)
      lockfile = nil

      # lockfile is only loaded once
      unless lockfile_or_path.nil?
        # loaded a Lockfile instance
        if lockfile_or_path.is_a? LockJar::Domain::Lockfile
          lockfile = lockfile_or_path

        # check if lockfile path is already loaded
        elsif LockJar::Registry.instance.lockfile_registered?(lockfile_or_path)
          return

        # convert lockfile path to a Lockfile instance
        else
          lockfile = LockJar::Domain::Lockfile.read(lockfile_or_path)
        end

        if opts[:local_repo].nil? && lockfile.local_repository
          opts[:local_repo] = lockfile.local_repository
        end
      end

      # set local_repo if passed in the block
      unless blk.nil?
        dsl = LockJar::Domain::Dsl.create(&blk)

        # set local_repo from block
        if opts[:local_repo].nil? && dsl.local_repository
          opts[:local_repo] = dsl.local_repository
        end
      end

      # registered merged lockfiles for lockfile
      if lockfile && !lockfile.merged.empty?
        lockfile.merged.each { |path| LockJar::Registry.instance.register_lockfile(path) }
      end

      dependencies = LockJar::Registry.instance.register_jars(list(lockfile, groups, opts, &blk))

      resolver(opts).load_to_classpath(dependencies)
    end

    private

    def lockfile_dependencies(lockfile, groups, with_locals = true)
      dependencies = []

      groups.each do |group|
        next unless lockfile.groups[group.to_s]
        dependencies += lockfile.groups[group.to_s]['dependencies']

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
