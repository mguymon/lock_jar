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
  class Runtime
    
    attr_reader :resolver
    
    def initialize( opts = {} )
      @resolver = LockJar::Resolver.new( opts )
    end
    
    def lock( jarfile = "Jarfile", opts = {} )
        lock_jar_file = nil
        
        if jarfile.is_a? LockJar::Dsl
          lock_jar_file = jarfile
        else
          lock_jar_file = LockJar::Dsl.evaluate( jarfile )
        end
        
        lock_jar_file.repositories.each do |repo|
          @resolver.add_remote_repository( repo )
        end
    
        lock_data = { 'scopes' => {} }
    
        if lock_jar_file.repositories.size > 0
          lock_data['repositories'] = lock_jar_file.repositories
        end
          
        lock_jar_file.notations.each do |scope, notations|
          
          dependencies = []
          notations.each do |notation|
            dependencies << {notation => scope}
          end
          
          resolved_notations = @resolver.resolve( dependencies )
          lock_data['scopes'][scope] = { 
            'dependencies' => notations,
            'resolved_dependencies' => resolved_notations } 
        end
    
        File.open( opts[:lockfile] || "Jarfile.lock", "w") do |f|
          f.write( lock_data.to_yaml )
        end
      end
    
      def list( jarfile_lock = "Jarfile.lock", scopes = ['compile', 'runtime'] )
        lock_data = YAML.load_file( jarfile_lock )
                
        dependencies = []
          
        scopes.each do |scope|
          if lock_data['scopes'][scope]
            dependencies += lock_data['scopes'][scope]['resolved_dependencies']
          end
        end
        
        dependencies
      end
      
      def load( jarfile_lock = "Jarfile.lock", scopes = ['compile', 'runtime'], &blk )
        dependencies = []
        
        if jarfile_lock
          if File.exists?(jarfile_lock)
            dependencies += read_jarfile( jarfile_lock, scopes )
          else
            warn( "LockJar jarfile_lock not found: #{jarfile_lock}" )
          end
        end
                
        if blk
          dsl = LockJar::Dsl.evaluate(&blk)
          dependencies += read_dsl( dsl, scopes )
        end
        
        dependencies.uniq!
        
        @resolver.load_jars_to_classpath( dependencies )
      end
      
      private
      def read_jarfile( jarfile_lock, scopes )
        lock_data = YAML.load_file( jarfile_lock )
        
        dependencies = []
         
        scopes.each do |scope|
          if lock_data['scopes'][scope]
            dependencies += lock_data['scopes'][scope]['resolved_dependencies']
          end
        end
        
        dependencies
      end
      
      def read_dsl( dsl, scopes )
        
        dependencies = []
         
        dsl.notations.each do |scope,notations|
          if notations && notations.size > 0
            dependencies += notations
          end
        end
        
        @resolver.resolve( dependencies )
      end
  end
end