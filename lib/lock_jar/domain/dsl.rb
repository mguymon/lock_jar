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
require 'lock_jar/domain/dsl_helper'

module LockJar
  module Domain
    class Dsl
  
      DEFAULT_GROUP = ['default']
      
      attr_accessor :notations, :repositories, :local_repository, :groups,
                    :maps, :excludes
      
      class << self
      
        def evaluate(jarfile = nil, &blk)
          if jarfile.nil? && blk.nil?
            raise "jarfile or block must be set"
          end
          
          
          builder = new
          
          if jarfile
            builder.instance_eval(DslHelper.read_file(jarfile.to_s), jarfile.to_s, 1)
          end      
              
          if blk
            builder.instance_eval(&blk)
          end      
          
          builder
        end
        
      end
      
      def initialize
  
        @repositories = []
        @notations = { 'default' => [] }
         
        @group_changed = false
          
        @present_group = 'default'
        
        @local_repository = nil
        @maps = {}
        @excludes = []
      end
      
      def exclude(*notations)
        @excludes += notations
      end
      
      def jar(notation, *args)
        opts = {}
        if args.last.is_a? Hash
          opts.merge!( args.last )
        end
        
        artifact( notation, opts )
      end
      
      def local( *args )
        if !args.empty? && File.directory?( File.expand_path( args.first ) )
          warn "[DEPRECATION] `local` to set local_repository is deprecated.  Please use `local_repo` instead."
          local_repo(args.first)
        else
          # XXX: support local artifacts
        end
      end
  
      def local_repo( path )
        @local_repository = path
      end
      
      alias_method :name, :local_repository
      
      # Map a dependency to another dependency or local directory.
      def map( notation, *args )
        @maps[notation] = args
      end
      
      # 
      def pom(path, *args)
        unless path =~ /\.xml$/i
          raise "#{path} is an invalid pom path"  
        end
        
        opts = { :scopes => ['runtime', 'compile'] }
          
        if args.last.is_a? Hash
          opts.merge! args.last
        end
        
        artifact( {path => opts[:scopes] }, opts )
      end
  
      def repository( url, opts = {} )
        @repositories << url
      end
  
      def group(*groups, &blk)
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
        warn "[DEPRECATION] `scope` is deprecated.  Please use `group` instead."
        group(*scopes,&blk)
      end
      
      private 
      def artifact(artifact, opts)
        
        groups = opts[:group] || opts[:groups] || opts[:group]
        
        if groups
          
          unless groups.is_a? Array
            groups = [groups]
          end
          
          # include present group if within a group block
          if @group_changed
            groups << @present_group
          end
          
        else
          groups = [@present_group]
        end
        
        if artifact
          groups.uniq.each do |group|
            group_key = group.to_s
            @notations[group_key] = [] unless @notations[group_key]
            @notations[group_key] << artifact
          end
        end
        
      end
      
    end
  end
end