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

require 'lock_jar/maven'

module LockJar
  module Domain::Pom::Uberjar
    class ManifestDsl
      attr_accessor :manifest

      def initialize
        @manifest = { 'Manifest-Version' => '1.0', 'Created-By' => 'LockJar'}
      end

      def title(val)
        @manifest['Implementation-Title'] = val
      end

      def version(val)
        @manifest['Implementation-Version'] = val
      end

      def main_class(val)
        @manifest['Main-Class'] = val
      end

      def created_by(val)
        @manifest['Created-By'] = val
      end

      def custom(name, value)
        @manifest[name] = value
      end

      def to_manifest
        copy = @manifest.dup

        manifest_txt = ""
        created_by = copy.delete 'Created-By'

        %w{Implementation-Title Implementation-Version Manifest-Version Main-Class}.each do |key|
          if copy.has_key? key
            manifest_txt << "#{key}: #{copy.delete(key)}\n"
          end
        end

        # set all the custom fields
        copy.each do |key,val|
          manifest_txt << "#{key}: #{val}\n"
        end

        # created by is always last
        manifest_txt << "Created-By: #{created_by}\n"

        manifest_txt
      end
    end
  end
end