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
  class Dsl

    attr_reader :notations
    attr_reader :repositories
    attr_reader :local_repository
    attr_reader :scopes
    
    class << self
    
      def evaluate(jarfile = nil, &blk)
        if jarfile.nil? && blk.nil?
          raise "jarfile or block must be set"
        end
        
        
        builder = new
        
        if jarfile
          builder.instance_eval(builder.read_file(jarfile.to_s), jarfile.to_s, 1)
        end      
            
        if blk
          builder.instance_eval(&blk)
        end      
        
        builder
      end
      
      def scopes
        ['compile', 'runtime', 'test']
      end
    end
    
    def initialize

      @repositories = []
      @notations = {}
       
      @scope_changed = false
        
      LockJar::Dsl.scopes.each do |scope|
        @notations[scope] = []
      end
        
      @present_scope = 'compile'
      
      @local_repository = nil
    end
    
    def local( path )
      @local_repository = path
    end
    
    def jar(notation, *args)
      opts = {}
      if args.last.is_a? Hash
        opts.merge!( args.last )
      end
      
      artifact( notation, opts )
    end
    
    # Pom default to all scopes, unless nested in a scope
    def pom(path, *args)
      opts = { }
        
      if args.last.is_a? Hash
        opts.merge!( args.last )
      end
      
      # if not scope opts and default scope, set to all
      unless opts[:scope] || opts[:scopes] || @scope_changed
        opts[:scope] = Dsl.scopes
      end
      
      artifact( path, opts )
    end
    
    def repository( url, opts = {} )
      @repositories << url
    end
    
    def scope(*scopes, &blk)
       @scope_changed = true
       scopes.each do |scope|
         @present_scope = scope.to_s
         yield
       end
       @scope_changed = false
       @present_scope = 'compile'
    end
    
    def read_file(file)
      File.open(file, "rb") { |f| f.read }
    end
    
    def merge( dsl )
      @repositories = (@repositories + dsl.repositories).uniq
      
      dsl.notations.each do |scope, notations|
        @notations[scope] = (@notations[scope] + notations).uniq         
      end
      
      self
    end
   
    private 
    def artifact(artifact, opts)
      
      scopes = opts[:scope] || opts[:scopes] || opts[:group]
      if scopes
        
        unless scopes.is_a? Array
          scopes = [scopes]
        end
        
        # include present scope if within a scope block
        if @scope_changed
          scopes << @present_scope
        end
        
      else
        scopes = [@present_scope]
      end
      
      if artifact
        scopes.each do |scope|
          scope = 'compile' if scope.to_s == 'development'
          
          if @notations[scope.to_s]
            @notations[scope.to_s] << artifact
          end
        end
      end
      
    end
    
  end
end