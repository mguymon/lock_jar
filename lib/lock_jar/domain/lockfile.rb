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

require 'yaml'
require 'set'
require 'lock_jar/version'

module LockJar
  module Domain
    # Class representation of the lock file
    class Lockfile
      attr_accessor :local_repository, :maps, :excludes, :remote_repositories,
                    :version, :groups, :gems, :merged

      # rubocop:disable Metrics/PerceivedComplexity
      def self.read(path)
        lock_data = fs_or_classpath(path)

        fail "lockfile #{path} not found" if lock_data.nil?

        Lockfile.new.tap do |lockfile|
          lockfile.version = lock_data['version'] || LockJar::VERSION
          lockfile.merged = lock_data['merged']
          lockfile.local_repository = lock_data['local_repository']
          lockfile.merged = lock_data['merged'] || []
          lockfile.maps = lock_data['maps'] || []
          lockfile.excludes = lock_data['excludes'] || []
          lockfile.groups = lock_data['groups'] || lock_data['scopes'] || {}
          lockfile.remote_repositories =
            Set.new(Array(lock_data['remote_repositories'] || lock_data['repositories']))
          lockfile.gems = lock_data['gems'] || []
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def self.fs_or_classpath(path)
        if File.exist? path
          YAML.load_file(path)

        # Lookup of Jarfile.lock in the classpath
        elsif Naether.platform == 'java' || path.start_with?('classpath:')
          stream = java.lang.Object.java_class.resource_as_stream("/#{path.gsub('classpath:', '')}")
          if stream
            reader = java.io.BufferedReader.new(java.io.InputStreamReader.new(stream))
            lines = ''
            while (line = reader.read_line)
              lines << line << "\n"
            end
            reader.close

            YAML.load(lines)
          end
        end
      end

      def initialize
        @groups = { 'default' => {} }
        @maps = []
        @excludes = []
        @remote_repositories = Set.new
        @gems = []
        @merged = []

        @version = LockJar::VERSION # default version
      end

      def to_hash
        lock_data = { 'version' => @version }

        lock_data['local_repository'] = local_repository unless local_repository.nil?

        lock_data['merged'] = merged unless merged.empty?

        lock_data['maps'] = maps if maps.size > 0

        lock_data['excludes'] = excludes if excludes.size > 0

        lock_data['gems'] = gems unless gems.empty?

        lock_data['groups'] = groups

        if remote_repositories.size > 0
          lock_data['remote_repositories'] = remote_repositories.to_a
        end

        lock_data
      end
      alias_method :to_h, :to_hash

      def to_yaml
        to_hash.to_yaml
      end

      def write(path)
        File.open(path, 'w') do |f|
          f.write(to_yaml)
        end
      end
    end
  end
end
