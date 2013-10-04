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
require 'lock_jar/domain/artifact'
require 'lock_jar/domain/pom/uberjar_dsl'
require 'lock_jar/domain/dsl_helper'

module LockJar
  module Domain
    class PomDsl

      attr_accessor :pom, :uberjar_dsl

      def initialize(parent, *args, &blk)
        @parent = parent

        if args.first.is_a? String
          pom_path(*args)
        end

        self.instance_eval(&blk) if blk
      end

      def uberjar(&blk)
        @uberjar_dsl = Pom::UberjarDsl.new(&blk)
      end

      private
      def pom_path(*args)

        @pom = args.shift

        unless @pom =~ /\.xml$/i
          raise "#{@pom} is an invalid pom path"
        end

        opts = { :scopes => ['runtime', 'compile'] }

        if args.last.is_a? Hash
          opts.merge! args.last
        end

        artifact = Artifact::Pom.new( @pom, opts[:scopes] )
        @parent.assign_groups( artifact, opts[:groups] )
      end
    end
  end
end