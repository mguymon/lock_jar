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
require 'lock_jar/domain/dsl_merger'
require 'lock_jar/domain/artifact'

module LockJar
  module Domain
    #
    class Dsl
      DEFAULT_GROUP = ['default'].freeze

      attr_accessor :artifacts, :remote_repositories, :local_repository, :groups,
                    :maps, :excludes, :merged, :clear_repositories

      attr_reader :file_path

      class << self
        def create(jarfile = nil, &blk)
          builder = new
          evaluate(builder, jarfile, &blk)
        end

        def evaluate(builder, jarfile = nil, &blk)
          fail 'jarfile or block must be set' if jarfile.nil? && blk.nil?

          builder.instance_eval(IO.read(jarfile.to_s), jarfile.to_s, 1) if jarfile

          builder.instance_eval(&blk) if blk

          builder
        end
      end

      def initialize
        @remote_repositories = []
        @artifacts = { 'default' => [] }
        @group_changed = false
        @present_group = 'default'
        @local_repository = nil
        @maps = {}
        @excludes = []
        @merged = []
        @clear_repositories = false
      end

      def exclude(*notations)
        @excludes += notations
      end

      def jar(notation, *args)
        opts = {}

        opts.merge!(args.last) if args.last.is_a? Hash

        artifact = Jar.new(notation)

        assign_groups(artifact, opts[:group])
      end

      def local(*args)
        return if args.empty?

        if File.directory?(File.expand_path(args.first))
          warn(
            '[DEPRECATED] `local` to set local_repository is deprecated. '\
            'Please use `local_repo` instead'
          )
          local_repo(args.first)
        else
          path = args.shift

          opts = {}

          opts.merge!(args.last) if args.last.is_a? Hash

          artifact = Local.new(path)

          assign_groups(artifact, opts[:group])
        end
      end

      def local_repo(path)
        @local_repository = path
      end

      alias_method :name, :local_repository

      # Map a dependency to another dependency or local directory.
      def map(notation, *args)
        @maps[notation] = args
      end

      #
      def pom(path, *args)
        fail "#{path} is an invalid pom path" unless path =~ /\.xml$/i

        opts = { scopes: %w(runtime compile) }

        opts.merge!(args.last) if args.last.is_a? Hash

        assign_groups(Pom.new(path, opts[:scopes]), opts[:groups])
      end

      def remote_repo(url, _opts = {})
        @remote_repositories << url
      end
      alias_method :remote_repository, :remote_repo
      alias_method :repository, :remote_repo

      def group(*groups, &_blk)
        @group_changed = true
        groups.each do |group|
          @present_group = group.to_s
          yield
        end
        @group_changed = false
        @present_group = 'default'
      end

      # @deprecated Please use {#group} instead
      def scope(*scopes, &blk)
        warn '[DEPRECATED] `scope` is deprecated.  Please use `group` instead.'
        group(*scopes, &blk)
      end

      def without_default_maven_repo
        @clear_repositories = true
      end

      private

      def assign_groups(artifact, groups = nil)
        if groups
          groups = Array(groups)

          # include present group if within a group block
          groups << @present_group if @group_changed

        else
          groups = [@present_group]
        end

        groups.uniq.each do |group|
          group_key = group.to_s
          @artifacts[group_key] = [] unless @artifacts[group_key]
          @artifacts[group_key] << artifact
        end if artifact
      end
    end
  end
end
