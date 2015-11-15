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
require 'naether/bootstrap'
require 'fileutils'

module LockJar
  #
  class Resolver
    attr_reader :opts
    attr_reader :naether

    def initialize(opts = {})
      @opts = opts
      local_repo = opts[:local_repo] || Naether::Bootstrap.default_local_repo

      # Bootstrap Naether
      Naether::Bootstrap.bootstrap_local_repo(local_repo, opts)

      # Bootstrapping naether will create an instance from downloaded jars.
      # If jars exist locally already, create manually
      @naether = Naether.create
      @naether.local_repo_path = local_repo if local_repo
      @naether.clear_remote_repositories if opts[:offline]
    end

    def remote_repositories
      @naether.remote_repository_urls
    end

    def clear_remote_repositories
      @naether.clear_remote_repositories
    end

    def add_remote_repository(repo)
      @naether.add_remote_repository(repo)
    end

    def resolve(dependencies, download_artifacts = true)
      @naether.dependencies = dependencies
      @naether.resolve_dependencies(download_artifacts)
      @naether.dependencies_notation
    end

    def dependencies_graph
      @naether.dependencies_graph
    end

    def download(dependencies)
      @naether.download_artifacts(dependencies)
    end

    def to_local_paths(notations)
      paths = []
      notations.each do |notation|
        if File.exist?(notation)
          paths << notation
        else
          paths += @naether.to_local_paths([notation])
        end
      end

      paths
    end

    def load_to_classpath(artifacts)
      paths = []
      notations = []

      artifacts.each do |art|
        if File.exist?(art)
          paths << art
        else
          notations << art
        end
      end

      paths += @naether.to_local_paths(notations)
      Naether::Java.load_paths(paths)

      paths
    end
  end
end
