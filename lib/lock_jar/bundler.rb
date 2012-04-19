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

require 'rubygems'
require 'bundler/dsl'
require 'lock_jar'
require 'lock_jar/dsl'

module Bundler
  class Dsl
    def lock_jar(&blk)
      @lock_jar_blk = blk
    end
    
    def to_definition(lockfile, unlock)
      @sources << @rubygems_source unless @sources.include?(@rubygems_source)
      definition = LockJarDefinition.new(lockfile, @dependencies, @sources, unlock)
      
      if @lock_jar_blk
        definition.lock_jar = LockJar::Dsl.evaluate( nil, &@lock_jar_blk )
      end
      
      definition
    end
  end
  
  class Environment
    def lock_jar
      @definition.lock_jar
    end
  end
  
  class LockJarDefinition < Bundler::Definition
    alias :lockjar_replaced_lock :lock
    attr_accessor :lock_jar
    
    def lock( file )
      LockJar.lock( lock_jar )
      
      lockjar_replaced_lock( file )
    end
  end
  
  class Runtime
    alias :lockjar_replaced_setup :setup
    alias :lockjar_replaced_require :require
    
    def setup(*groups)
      scopes = []
      if groups && groups.size == 0
        scopes = ["compile","runtime"]
      else
        groups.each do |group|
          if "development" == group.to_s 
            scopes << "compile"
          elsif "default" == group.to_s
            scopes << "compile"  << "runtime"
          end
        end
      end
      
      LockJar.load( scopes.uniq )
      
      lockjar_replaced_setup( *groups )
    end
    
    def require(*groups)
      scopes = []
        
      if groups && groups.size == 0
        scopes = ["compile","runtime"]
      else
        groups.each do |group|
          if "development" == group.to_s 
            scopes << "compile"
          elsif "default" == group.to_s
            scopes << "compile"  << "runtime"
          end
        end
      end
      LockJar.load( scopes.uniq )
      
      lockjar_replaced_require( *groups )
    end
  end
end