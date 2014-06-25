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

require 'set'
require 'lock_jar/maven'
require 'naether/notation'

module LockJar
  module Domain
    
    
    class Artifact
      include Comparable
      attr_reader :type
      
      def <=>(another_artifact)
        if another_artifact.is_a? Artifact
          to_urn <=> another_artifact.to_urn
        else
          to_urn <=> another_artifact.to_s
        end
      end
      
      def resolvable?
        true
      end
    end
    
    class Jar < Artifact
      attr_reader :notation
      
      def initialize( notation )
        @type = 'jar'
        @notation = Naether::Notation.new( notation ).to_notation
      end
      
      def to_urn
        "jar:#{notation}"
      end
      
      def to_dep
        notation
      end
    end
    
    class Local < Artifact
      attr_reader :path
      def initialize( path )
        @type = 'local'
        @path = path
      end
      
      def to_urn
        "local:#{path}"
      end
      
      def to_dep
        path
      end

      def resolvable?
        false
      end
    end
    
    class Pom < Artifact
      attr_reader :path, :scopes
      
      def initialize( _path, _scopes = ['compile','runtime'] )
        @type = 'pom'
        @path = _path
        @scopes = _scopes
      end
      
      def to_urn
        "pom:#{path}"
      end
      
      def to_dep
        { path => scopes }
      end
      
      def notations
        LockJar::Maven.dependencies( path, scopes )  
      end
      
      def ==(another_artifact)
        self.<=>(another_artifact) == 0
      end
      
      def <=>(another_artifact)
        if another_artifact.is_a? Pom
          if to_urn == another_artifact.to_urn
            return 0 if Set.new(scopes) == Set.new(another_artifact.scopes)
            
            # XXX: this is not a reliable way to compare. 
            if scopes.size > another_artifact.scopes.size
              return 1
            else
              return -1
            end
          else
            to_urn <=> another_artifact.to_urn
          end
        else
          super
        end
      end
    end
    
  end
end