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

module LockJar
  module Domain
    # Merge DSLs
    class DslMerger
      attr_reader :into_dsl, :from_dsl, :into_groups

      # @param [LockJar::Domain::Dsl] into_dsl dsl that is merged into
      # @param [LockJar::Domain::Dsl] from_dsl dsl that is merged from
      # @param [String] into_group force only runtime and default groups to be
      #                            loaded into this group
      def initialize(into_dsl, from_dsl, into_groups = nil)
        @into_dsl = into_dsl
        @from_dsl = from_dsl
        @into_groups = into_groups
      end

      # Merge LockJar::Domain::Dsl
      # @return [LockJar::Domain::Dsl]
      def merge
        merged_dsl = into_dsl.dup

        merged_dsl.remote_repositories = remote_repositories

        merged_dsl.artifacts = artifact_groups(into_groups)

        from_dsl.maps.each do |artifact, paths|
          maps = into_dsl.maps[artifact] || []
          merged_dsl.maps[artifact] = (maps + paths).uniq
        end

        from_dsl.excludes.each do |exclude|
          merged_dsl.excludes << exclude unless into_dsl.excludes.include? exclude
        end

        merged_dsl.merged << from_dsl.file_path if from_dsl.file_path

        merged_dsl
      end

      private

      def remote_repositories
        (into_dsl.remote_repositories + from_dsl.remote_repositories).uniq
      end

      def artifact_groups(restrict = nil)
        artifacts = Hash.new { |hash, key| hash[key] = [] }

        from_dsl.artifacts.each do |group, group_artifacts|
          next if restrict && !restrict.include?(group)
          artifacts[group] += into_dsl.artifacts[group] || []
          group_artifacts.each do |art|
            artifacts[group] << art unless artifacts[group].include? art
          end
        end

        artifacts
      end
    end
  end
end
