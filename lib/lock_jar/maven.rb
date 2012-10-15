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

require 'lock_jar/runtime'
require 'naether/maven'

module LockJar
  
  # Helper for providing Maven specific operations
  #
  # @author Michael Guymon
  # 
  class Maven
    
    class << self
      
      #
      # Get the version of a POM
      #
      # @param [String] pom_path path to the pom
      #
      # @return [String] version of POM
      #
      def pom_version( pom_path )
        maven = Naether::Maven.create_from_pom( pom_path )
        maven.version()
      end
      
      #
      # Get dependencies of a Pom
      #
      # @param [String] pom_path path to the pom
      # @param [Array] scopes
      #
      # @return [String] version of POM
      #
      def dependencies( pom_path, scopes = ['compile', 'runtime'] )
        maven = Naether::Maven.create_from_pom( pom_path )
        maven.dependencies(scopes)
      end
      
      #
      # Write a POM from list of notations
      #
      # @param [String] pom notation
      # @param [String] file_path path of new pom
      # @param [Hash] opts
      # @option opts [Boolean] :include_resolved to add dependencies of resolve dependencies from Jarfile.lock. Default is true.
      # @option opts [Array] :dependencies Array of of mixed dependencies:
      #  * [String] Artifact notation, such as groupId:artifactId:version, e.g. 'junit:junit:4.7' 
      #  * [Hash] of a single artifaction notation => scope - { 'junit:junit:4.7' => 'test' }
      #
      def write_pom( notation, file_path, opts = {} )
        opts = {:include_resolved => true}.merge( opts )
        
        maven = Naether::Maven.create_from_notataion( notation )
        
        if opts[:include_resolved]
          # Passes in nil to the resolver to get the cache
          maven.load_naether( Runtime.instance.resolver.naether )
        end
        
        if opts[:dependencies]
          opts[:dependencies].each do |dep|
            if dep.is_a? Array
              maven.add_dependency(dep[0], dep[1])
            else
              maven.add_dependency(dep)
            end
          end
        end
        maven.write_pom( file_path )
      end
      
      #
      # Deploy an artifact to a Maven repository
      #
      # @param [String] notation of artifact
      # @param [String] file_path path to the Jar
      # @param [String] url Maven repository deploying to
      # @param [Hash] deploy_opts options for deploying 
      # @param [Hash] lockjar_opts options for initializing LockJar
      #
      def deploy_artifact( notation, file_path, url, deploy_opts = {}, lockjar_opts = {} )
        Runtime.instance.resolver(lockjar_opts).naether.deploy_artifact( notation, file_path, url, deploy_opts )
      end
      
      #
      # Install an artifact to a local repository
      #
      # @param [String] notation of artifact
      # @param [String] pom_path path to the pom
      # @param [String] jar_path path to the jar
      # @param [Hash] opts options
      #
      def install( notation, pom_path, jar_path, opts = {} )
        Runtime.instance.resolver(opts).naether.install( notation, pom_path, jar_path )
      end
    end
  end
end