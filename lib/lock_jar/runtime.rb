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
            lock_jar_file = LockJar::Domain::Dsl.evaluate( jarfile )
          end
        end
        
        unless blk.nil?
          dsl = LockJar::Domain::Dsl.evaluate(&blk)
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
        
        default_notations = lock_jar_file.notations.delete( 'default' )
        default_resolved_notations = []
        if default_notations && !default_notations.empty?
           default_resolved_notations = resolver(opts).resolve( default_notations, opts[:download] == true )
          
          if lockfile.excludes
            lockfile.excludes.each do |exclude|
              default_resolved_notations.delete_if { |dep| dep =~ /#{exclude}/ }
            end
          end
          
          lockfile.groups['default'] = { 
              'dependencies' => sort_notations(default_notations),
              'resolved_dependencies' => default_resolved_notations.sort } 
        end
        
        lock_jar_file.notations.each do |group, notations|
          
          dependencies = []
          notations.each do |notation|
            dependencies << notation
          end
          
          if dependencies.size > 0
            # remove duplicated deps
            dependencies -= default_notations
            
            # add defaults to deps
            dependencies += default_notations
            
            resolved_notations = resolver(opts).resolve( dependencies, opts[:download] == true )
            
            # remove duplicated resolved deps
            resolved_notations -= default_resolved_notations
            
            lockfile.remote_repositories = resolver(opts).remote_repositories.uniq
            
            if lockfile.excludes
              lockfile.excludes.each do |exclude|
                resolved_notations.delete_if { |dep| dep =~ /#{exclude}/ }
              end
            end
            
            lockfile.groups[group] = { 
              'dependencies' => sort_notations(notations),
              'resolved_dependencies' => resolved_notations.sort } 
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
          dsl = LockJar::Domain::Dsl.evaluate(&blk)
          dependencies += dsl_dependencies( dsl, groups )
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
          resolver(opts).to_local_paths( dependencies.uniq )
          
        else
          dependencies.uniq
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
          dsl = LockJar::Domain::Dsl.evaluate(&blk)
          
          if opts[:local_repo].nil? && dsl.local_repository
            opts[:local_repo] = dsl.local_repository
          end
        end
        
        LockJar::Registry.instance.register_lockfile( jarfile_lock )
        dependencies = LockJar::Registry.instance.register_jars( list( jarfile_lock, groups, opts, &blk ) )
                
        resolver(opts).load_to_classpath( dependencies )
      end
      
      private
      
      def sort_notations(notations)
        notations.sort_by! do |x,y|
          if x.is_a? Hash
            unless y.is_a? Hash
              -1
            end
          elsif y.is_a? Hash
            1
          end
          
          x <=> y
        end
      end
      
      def lockfile_dependencies( lockfile, groups)
        dependencies = []
         
        groups.each do |group|
          if lockfile.groups[group]
            dependencies += lockfile.groups[group]['resolved_dependencies']
          end
        end
        
        dependencies
      end
      
      def dsl_dependencies( dsl, groups )
        
        dependencies = []
         
        dsl.notations.each do |group,notations|
          if notations && notations.size > 0
            dependencies += notations
          end
        end
        
        dependencies
      end
  end
  
end
