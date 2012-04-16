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
    end
    
    def jar(notation, *args)
      if notation
        @notations[@present_scope] << notation
      end
    end
    
    # Pom default to all scopes, unless nested in a scope
    def pom(path, *args)
      if @scope_changed
        @notations[@present_scope] << path
      else
        LockJar::Dsl.scopes.each do |scope|
          @notations[scope] << path
        end
      end
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
  end
end