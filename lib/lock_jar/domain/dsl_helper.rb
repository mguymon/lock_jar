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
          
          from_dsl.notations.each do |group, notations|
            group_notations = into_dsl.notations[group] || []
            into_dsl.notations[group] = (group_notations + notations).uniq         
          end
          
          from_dsl.maps.each do |notation,paths|
            existing_map = into_dsl.maps[notation]
            if existing_map
              into_dsl.maps[notation] = (existing_map + paths).uniq
            else
              into_dsl.maps[notation] = paths
            end
          end
          
          from_dsl.excludes.each do |exclude|
            into_dsl.excludes << exclude
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