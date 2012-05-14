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
      # @param [Hash] options
      #
      # @return [String] version of POM
      #
      def pom_version( pom_path, opts = {} )
        Runtime.instance.resolver(opts).naether.pom_version( pom_path )
      end
      
      #
      # Write a POM from list of notations
      #
      # @param [Array] notations 
      # @param [String] file_path path of new pom
      # @param [Hash] options
      def write_pom( notations, file_path, opts = {} )
        Runtime.instance.resolver(opts).naether.write_pom( notations, file_path )
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