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
require 'naether'
require 'fileutils'

module LockJar
  class Resolver
    
    attr_reader :opts
    attr_reader :naether
    
    def initialize( opts = {} )
      @opts = opts
      local_repo = opts[:local_repo] || Naether::Bootstrap.default_local_repo
        
      # Bootstrap Naether
      jars = []
      temp_jar_dir = File.join(local_repo, '.lock_jar', 'naether' )
      deps = Naether::Bootstrap.check_local_repo_for_deps( local_repo )
      if deps[:missing].size > 0
        deps = Naether::Bootstrap.download_dependencies( temp_jar_dir, deps.merge( :local_repo => local_repo ) )
        if deps[:downloaded].size > 0
                    
          unless File.directory?( temp_jar_dir )
            FileUtils.mkdir_p jar_dir
          end
          
          @naether = Naether::Bootstrap.install_dependencies_to_local_repo( temp_jar_dir, :local_repo => local_repo )
          jars = jars + deps[:downloaded].map{ |jar| jar.values[0] }
        else
          # XXX: download failed?            
        end
        
      # Remove bootstrap jars, they have been installed to the local repo
      elsif File.exists?( temp_jar_dir )        
        FileUtils.rm_rf temp_jar_dir
      end
      
      jars = jars + deps[:exists].map{ |jar| jar.values[0] }
        
      # Bootstrapping naether will create an instance from downloaded jars. 
      # If jars exist locally already, create manually
      if @naether.nil?  
        jars << Naether::JAR_PATH
        @naether = Naether.create_from_jars( jars )
      end
      
      @naether.local_repo_path = opts[:local_repo].to_s if opts[:local_repo]
      
      
      @naether.clear_remote_repositories if opts[:offline]
    end
    
    def remote_repositories
      @naether.remote_repository_urls
    end
    
    def add_remote_repository( repo )
      @naether.add_remote_repository( repo )
    end
    
    def resolve( dependencies, download_artifacts = true )
      @naether.dependencies = dependencies
      @naether.resolve_dependencies( download_artifacts )
      @naether.dependenciesNotation
    end
    
    def download( dependencies )
      @naether.download_artifacts( dependencies )
    end
    
    def to_local_paths( notations )
      paths = []   
      notations.each do |notation|
        if File.exists?(notation)
          paths << notation
        else
          paths = paths + @naether.to_local_paths( [notation] )
        end
      end
      
      paths
    end
    
    def load_to_classpath( notations )
      dirs = []
      jars = [] 
        
      notations.each do |notation|
        if File.directory?(notation)
          dirs << notation
        else
          jars << notation
        end
      end
      
      Naether::Java.load_paths( dirs )
      
      jars = @naether.to_local_paths( jars )
      Naether::Java.load_jars( jars )
      
      dirs + jars
    end
  end
end