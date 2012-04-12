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
    def self.evaluate(jarfile)
      builder = new
      builder.instance_eval(builder.read_file(jarfile.to_s), jarfile.to_s, 1)
      #builder.to_definition(lockfile, unlock)
      
      builder
    end
    
    attr_reader :notations
    attr_reader :repositories
    attr_reader :scopes
    
    def initialize

      @repositories = []
      @scopes = ['compile', 'runtime', 'test']
      @notations = {}
      @poms = []
       
      @scope_changed = false
        
      @scopes.each do |scope|
        @notations[scope] = []
      end
        
      @present_scope = 'compile'
    end
    
    def jar(notation, *args)
      @notations[@present_scope] << notation
    end
    
    # Pom default to all scopes, unless nested in a scope
    def pom(path, *args)
      if @scope_changed
        @notations[@present_scope] << path
      else
        @scopes.each do |scope|
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
    
  end
end