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
    class DslHelper
  
      class << self
      
        def merge( into_dsl, from_dsl )
          into_dsl.remote_repositories = (into_dsl.remote_repositories + from_dsl.remote_repositories).uniq
          
          from_dsl.artifacts.each do |group, artifacts|
            group_artifacts = into_dsl.artifacts[group] || []
            artifacts.each do |art|
              unless group_artifacts.include? art
                group_artifacts << art
              end
            end
            into_dsl.artifacts[group] = group_artifacts
          end
          
          from_dsl.maps.each do |artifact,paths|
            existing_map = into_dsl.maps[artifact]
            if existing_map
              into_dsl.maps[artifact] = (existing_map + paths).uniq
            else
              into_dsl.maps[artifact] = paths
            end
          end
          
          from_dsl.excludes.each do |exclude|
            unless into_dsl.include? exclude
              into_dsl.excludes << exclude
            end
          end
          
          if from_dsl.file_path
            into_dsl.merged << from_dsl.file_path
          end
          
          into_dsl
        end
      
        def read_file(file)
          File.open(file, "rb") { |f| f.read }
        end
      end
    end
  end
end