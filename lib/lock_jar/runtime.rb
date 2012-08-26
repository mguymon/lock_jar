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
require 'lock_jar/dsl'
require 'lock_jar/runtime'

module LockJar
  class Runtime
    include Singleton
    
    attr_reader :current_resolver
    
    def resolver( opts = {} )
      if opts[:local_repo]
        opts[:local_repo] = File.expand_path(opts[:local_repo])
      end
      
      # XXX: opts for a method will cause resolver to reload
      if @current_resolver.nil? || opts != @current_resolver.opts
        @current_resolver = LockJar::Resolver.new( opts )
      end
      
      @current_resolver
    end
    
    def install( jarfile_lock, scopes = ['compile', 'runtime'], opts = {}, &blk )
      deps = list( jarfile_lock, scopes, opts, &blk )
      files = resolver(opts).download( deps )
      
      files
    end
    
    def lock( jarfile, opts = {}, &blk )
      
        opts = {:download => true }.merge( opts )
      
        lock_jar_file = nil
        
        if jarfile
          if jarfile.is_a? LockJar::Dsl
            lock_jar_file = jarfile
          else
            lock_jar_file = LockJar::Dsl.evaluate( jarfile )
          end
        end
        
        unless blk.nil?
          dsl = LockJar::Dsl.evaluate(&blk)
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
        
        lock_jar_file.repositories.each do |repo|
          resolver(opts).add_remote_repository( repo )
        end
        
        lock_data = { }

        unless lock_jar_file.local_repository.nil?
          lock_data['local_repository'] = lock_jar_file.local_repository
          
          if needs_force_encoding
            lock_data['local_repository'] = lock_data['local_repository'].force_encoding("UTF-8")
          end
        end
          
        lock_data['repositories'] = resolver(opts).remote_repositories.uniq
        if needs_force_encoding
          lock_data['repositories'].map! { |repo| repo.force_encoding("UTF-8") }
        end     
        
        if lock_jar_file.maps.size > 0
          lock_data['maps'] = lock_jar_file.maps
        end
        
        if lock_jar_file.excludes.size > 0 
          lock_data['excludes'] = lock_jar_file.excludes
            
          if needs_force_encoding
            lock_data['excludes'].map! { |exclude| exclude.force_encoding("UTF-8") }
          end
        end
        
        lock_data['scopes'] = {} 
          
        lock_jar_file.notations.each do |scope, notations|
          
          if needs_force_encoding
            notations.map! { |notation| notation.force_encoding("UTF-8") }
          end
          
          dependencies = []
          notations.each do |notation|
            dependencies << {notation => scope}
          end
          
          if dependencies.size > 0
            resolved_notations = resolver(opts).resolve( dependencies, opts[:download] == true )
            
            if lock_data['excludes']
              lock_data['excludes'].each do |exclude|
                resolved_notations.delete_if { |dep| dep =~ /#{exclude}/ }
              end
            end
            
            lock_data['scopes'][scope] = { 
              'dependencies' => notations,
              'resolved_dependencies' => resolved_notations } 
          end
        end
    
        File.open( opts[:lockfile] || "Jarfile.lock", "w") do |f|
          f.write( lock_data.to_yaml )
        end
        
        lock_data
      end
    
      def list( jarfile_lock, scopes = ['compile', 'runtime'], opts = {}, &blk )
        dependencies = []
        maps = []
            
        if jarfile_lock
          lockfile = read_lockfile( jarfile_lock)
          dependencies += lockfile_dependencies( lockfile, scopes )
          maps = lockfile['maps']
        end
        
        unless blk.nil?
          dsl = LockJar::Dsl.evaluate(&blk)
          dependencies += dsl_dependencies( dsl, scopes )
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
      
      def load( jarfile_lock, scopes = ['compile', 'runtime'], opts = {}, &blk )
        if jarfile_lock
          lockfile = read_lockfile( jarfile_lock )
  
          if opts[:local_repo].nil? && lockfile['local_repo']
            opts[:local_repo] = lockfile['local_repo']
          end
        end
        
        unless blk.nil?
          dsl = LockJar::Dsl.evaluate(&blk)
          
          if opts[:local_repo].nil? && dsl.local_repository
            opts[:local_repo] = dsl.local_repository
          end
        end
        
        dependencies = list( jarfile_lock, scopes, opts, &blk )
                
        resolver(opts).load_to_classpath( dependencies )
      end
      
      def read_lockfile( jarfile_lock )
        YAML.load_file( jarfile_lock )
      end
      
      private
      
      def lockfile_dependencies( lockfile, scopes)
        dependencies = []
         
        scopes.each do |scope|
          if lockfile['scopes'][scope]
            dependencies += lockfile['scopes'][scope]['resolved_dependencies']
          end
        end
        
        dependencies
      end
      
      def dsl_dependencies( dsl, scopes )
        
        dependencies = []
         
        dsl.notations.each do |scope,notations|
          if notations && notations.size > 0
            dependencies += notations
          end
        end
        
        dependencies
      end

      private
      def needs_force_encoding
        @needs_force_encoding || @needs_force_encoding = RUBY_VERSION =~ /^1.9/
      end
  end
  
end