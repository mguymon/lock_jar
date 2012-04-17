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
      if @current_resolver.nil? || opts != @current_resolver.opts
        @current_resolver = LockJar::Resolver.new( opts )
      end
      
      @current_resolver
    end
    
    def lock( jarfile, opts = {} )
        lock_jar_file = nil
        
        if jarfile.is_a? LockJar::Dsl
          lock_jar_file = jarfile
        else
          lock_jar_file = LockJar::Dsl.evaluate( jarfile )
        end
        
        # If not set in opts, and is set in  dsl
        if opts[:local_repo].nil? && lock_jar_file.local_repository
          opts[:local_repo] = lock_jar_file.local_repository 
        end
        
        lock_jar_file.repositories.each do |repo|
          resolver(opts).add_remote_repository( repo )
        end
        
        lock_data = { }
    
        if lock_jar_file.repositories.size > 0
          lock_data['repositories'] = lock_jar_file.repositories
        end
        
        unless lock_jar_file.local_repository.nil?
          lock_data['local_repository'] = lock_jar_file.local_repository
        end
          
        lock_data['scopes'] = {} 
        
        lock_jar_file.notations.each do |scope, notations|
          
          dependencies = []
          notations.each do |notation|
            dependencies << {notation => scope}
          end
          
          resolved_notations = resolver(opts).resolve( dependencies )
          lock_data['scopes'][scope] = { 
            'dependencies' => notations,
            'resolved_dependencies' => resolved_notations } 
        end
    
        File.open( opts[:lockfile] || "Jarfile.lock", "w") do |f|
          f.write( lock_data.to_yaml )
        end
      end
    
      def list( jarfile_lock, scopes = ['compile', 'runtime'], opts = {}, &blk )
        dependencies = []
                
        if jarfile_lock
          dependencies += lockfile_dependencies( read_lockfile( jarfile_lock), scopes )
        end
        
        unless blk.nil?
          dsl = LockJar::Dsl.evaluate(&blk)
          dependencies += resolve_dsl( dsl, scopes, opts )
        end
        
        dependencies.uniq
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
        
        dependencies = list( jarfile_lock, scopes, &blk )
        
        resolver(opts).load_jars_to_classpath( dependencies )
      end
      
      private
      def read_lockfile( jarfile_lock )
        YAML.load_file( jarfile_lock )
      end
      
      def lockfile_dependencies( lockfile, scopes)
        dependencies = []
         
        scopes.each do |scope|
          if lockfile['scopes'][scope]
            dependencies += lockfile['scopes'][scope]['resolved_dependencies']
          end
        end
        
        dependencies
      end
      
      def resolve_dsl( dsl, scopes, opts )
        
        dependencies = []
         
        dsl.notations.each do |scope,notations|
          if notations && notations.size > 0
            dependencies += notations
          end
        end
        
        resolver(opts).resolve( dependencies )
      end
  end
end