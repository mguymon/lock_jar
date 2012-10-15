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

require 'rubygems'
require "yaml"
require 'singleton'
require 'lock_jar/resolver'
require 'lock_jar/runtime'
require 'lock_jar/registry'
require 'lock_jar/domain/dsl'
require 'lock_jar/domain/lockfile'

module LockJar
  class Runtime
    include Singleton
    
    attr_reader :current_resolver
    
    def resolver( opts = {} )
      
      # XXX: Caches the resolver by the options. Passing in nil opts will replay
      #      from the cache. This need to change.
      
      unless opts.nil?
        if opts[:local_repo]
          opts[:local_repo] = File.expand_path(opts[:local_repo])
        end
      else
        if @current_resolver
          opts = @current_resolver.opts
        else
          opts = {}
        end
      end
      
      if @current_resolver.nil? || opts != @current_resolver.opts
        @current_resolver = LockJar::Resolver.new( opts )
      end
      
      @current_resolver
    end
    
    def install( jarfile_lock, groups = ['default'], opts = {}, &blk )
      deps = list( jarfile_lock, groups, opts, &blk )
      
      lockfile = LockJar::Domain::Lockfile.read( jarfile_lock )
      lockfile.remote_repositories.each do |repo|
          resolver(opts).add_remote_repository( repo )
      end
      
      files = resolver(opts).download( deps )
      
      files
    end
    
    def lock( jarfile, opts = {}, &blk )
      
        opts = {:download => true }.merge( opts )
      
        lock_jar_file = nil
        
        if jarfile
          if jarfile.is_a? LockJar::Domain::Dsl
            lock_jar_file = jarfile
          else
            lock_jar_file = LockJar::Domain::Dsl.create( jarfile )
          end
        end
        
        unless blk.nil?
          dsl = LockJar::Domain::Dsl.create(&blk)
          if lock_jar_file.nil?
            lock_jar_file = dsl
          else
            lock_jar_file.merge( dsl )
          end
        end

        
        # If not set in opts, and is set in  dsl
        if opts[:local_repo].nil? && lock_jar_file.local_repository
          opts[:local_repo] = lock_jar_file.local_repository 
        end
        
        lock_jar_file.remote_repositories.each do |repo|
          resolver(opts).add_remote_repository( repo )
        end
        
        lockfile = LockJar::Domain::Lockfile.new

        unless lock_jar_file.local_repository.nil?
          lockfile.local_repository = lock_jar_file.local_repository
        end
                
        if lock_jar_file.maps.size > 0
          lockfile.maps = lock_jar_file.maps
        end
        
        if lock_jar_file.excludes.size > 0 
          lockfile.excludes = lock_jar_file.excludes
        end
        
        default_artifacts = lock_jar_file.artifacts.delete( 'default' )
        if default_artifacts && !default_artifacts.empty?
           lockfile.groups['default'] = resolve_dependencies( [], [], default_artifacts, lockfile.excludes, opts )
        end
         
        lock_jar_file.artifacts.each do |group, artifacts|
          
          group_artifacts = artifacts
          
          if group_artifacts.size > 0
            
            # remove duplicated deps
            group_artifacts -= default_artifacts
            
            # add defaults to deps
            group_artifacts += default_artifacts
            
            lockfile.groups[group] = resolve_dependencies( default_artifacts, lockfile.groups['default']['dependencies'], group_artifacts, lockfile.excludes, opts )
          end
        end
    
        lockfile.write( opts[:lockfile] || "Jarfile.lock" )
        
        lockfile
      end
    
      def list( jarfile_lock, groups = ['default'], opts = {}, &blk )
        dependencies = []
        maps = []
            
        if jarfile_lock
          lockfile = LockJar::Domain::Lockfile.read( jarfile_lock)
          dependencies += lockfile_dependencies( lockfile, groups )
          maps = lockfile.maps
        end
        
        unless blk.nil?
          dsl = LockJar::Domain::Dsl.create(&blk)
          dependencies += dsl_dependencies( dsl, groups ).map(&:to_dep)
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
        
        if opts[:resolve]
          dependencies = resolver(opts).resolve( dependencies )
        end
        
        if opts[:local_paths]
          opts.delete( :local_paths ) # remove list opts so resolver is not reset
          resolver(opts).to_local_paths( dependencies )
          
        else
          dependencies
        end
      end
      
      # Load paths from a lockfile or block. Paths are loaded once per lockfile.
      # 
      # @param [String] jarfile_lock the lockfile
      # @param [Array] groups to load into classpath
      # @param [Hash] opts
      # @param [Block] blk
      def load( jarfile_lock, groups = ['default'], opts = {}, &blk )
        
        # lockfile is only loaded once
        if !jarfile_lock.nil? && LockJar::Registry.instance.lockfile_registered?( jarfile_lock )
          return  
        end
        
        if jarfile_lock
          lockfile = LockJar::Domain::Lockfile.read( jarfile_lock )
          
          if opts[:local_repo].nil? && lockfile.local_repository
            opts[:local_repo] = lockfile.local_repository
          end
        end
        
        unless blk.nil?
          dsl = LockJar::Domain::Dsl.create(&blk)
          
          if opts[:local_repo].nil? && dsl.local_repository
            opts[:local_repo] = dsl.local_repository
          end
        end
        
        LockJar::Registry.instance.register_lockfile( jarfile_lock )
        dependencies = LockJar::Registry.instance.register_jars( list( jarfile_lock, groups, opts, &blk ) )
                
        resolver(opts).load_to_classpath( dependencies )
      end
      
      private
      
      def lockfile_dependencies( lockfile, groups)
        dependencies = []
         
        groups.each do |group|
          if lockfile.groups[group.to_s]
            dependencies += lockfile.groups[group.to_s]['dependencies']
          end
        end
        
        dependencies
      end
      
      def dsl_dependencies( dsl, groups )
        
        dependencies = []
         
        groups.each do |group|
          if dsl.artifacts[group.to_s]
            dependencies += dsl.artifacts[group.to_s]
          end
        end
        
        dependencies
      end
      
      def resolve_dependencies( default_artifacts, default_notations, artifacts, excludes, opts = {} )
        resolved_notations = []
        if artifacts && !artifacts.empty?
           resolved_notations = resolver(opts).resolve( artifacts.map(&:to_dep), opts[:download] == true )
          
          if excludes
            excludes.each do |exclude|
              resolved_notations.delete_if { |dep| dep =~ /#{exclude}/ }
            end
          end
          
          lock_data = { 'dependencies' => (resolved_notations - default_notations).sort }
          lock_data['artifacts'] = []
          artifacts.each do |artifact,deps|
            
            if default_artifacts.include? artifact
              next
            end
            
            artifact_data = {}
            if artifact.is_a? LockJar::Domain::Jar
              artifact_data["transitive"] = resolver(opts).dependencies_graph[artifact.notation].to_hash
              
            elsif artifact.is_a? LockJar::Domain::Pom
              artifact_data['scopes'] = artifact.scopes
              
              # iterate each dependency in Pom to map transitive dependencies
              transitive = {}
              artifact.notations.each do |notation| 
                transitive.merge!( resolver(opts).dependencies_graph[notation] )
              end
              artifact_data["transitive"] = transitive
              
            elsif artifact.is_a? LockJar::Domain::Local
              # xXX: support local artifacts
            else
              # XXX: handle unsupported artifact
              
            end
            
            # xxX: set required_by ?
            
            lock_data['artifacts'] << { artifact.to_urn => artifact_data }
          end
          
          lock_data
      end
    end
  end
end
