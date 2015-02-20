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
require 'lock_jar/version'

module LockJar
  module Domain
    class Lockfile

      attr_accessor :local_repository, :maps, :excludes, :remote_repositories,
                    :version, :groups, :gems, :merged

      def self.read( path )
        lockfile = Lockfile.new

        lock_data = YAML.load_file( path )

        lockfile.version = lock_data['version'] || LockJar::VERSION
        lockfile.merged = lock_data['merged']
        lockfile.local_repository = lock_data['local_repository']
        lockfile.merged = lock_data['merged'] || []
        lockfile.maps = lock_data['maps'] || []
        lockfile.excludes = lock_data['excludes'] || []
        lockfile.groups = lock_data['groups'] || lock_data['scopes'] || {}
        lockfile.remote_repositories = lock_data['remote_repositories'] || lock_data['repositories'] || []
        lockfile.gems = lock_data['gems'] || []
        lockfile
      end

      def initialize
        @groups = { 'default' => {} }
        @maps = []
        @excludes = []
        @remote_repositories = []
        @gems = []
        @merged = []

        @version = LockJar::VERSION # default version
      end

      def to_hash
        lock_data = { 'version' => @version }

        unless local_repository.nil?
          lock_data['local_repository'] = local_repository
        end

        unless merged.empty?
          lock_data['merged'] = merged
        end

        if maps.size > 0
          lock_data['maps'] = maps
        end

        if excludes.size > 0
          lock_data['excludes'] = excludes
        end

        unless gems.empty?
          lock_data['gems'] = gems
        end

        lock_data['groups'] = groups

        if remote_repositories.size > 0
          lock_data['remote_repositories'] = remote_repositories
        end

        lock_data
      end

      def to_yaml
        to_hash.to_yaml
      end

      def write( path )
        File.open( path, "w") do |f|
          f.write( to_yaml )
        end
      end
    end
  end
end
