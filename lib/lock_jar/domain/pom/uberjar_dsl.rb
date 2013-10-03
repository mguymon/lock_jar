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
require 'lock_jar/domain/pom'
require 'lock_jar/domain/pom/uberjar/manifest_dsl'

module LockJar
  module Domain::Pom
    class UberjarDsl

      attr_accessor :local_jars, :appenders, :callbacks, :manifest, :name

      def initialize(*args, &blk)
        @appenders = []
        @local_jars = []
        @callbacks = {}
        self.instance_eval(&blk) if blk
      end

      def explode_appenders(appenders)
        unless appenders.is_a? Array
          appenders = [appenders]
        end

        @appenders += appenders
      end

      def explode_local_jars(*jars)
        unless jars.is_a? Array
          jars = [jars]
        end
        @local_jars += jars
      end

      def build_manifest(&blk)
        @manifest = Uberjar::ManifestDsl.new
        @manifest.instance_eval(&blk)
      end

      def before_jar(&blk)
        @callbacks[:before_jar] = blk
      end

      def jar_name(name)
        @name = name
      end
    end
  end
end