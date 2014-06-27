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
    class JarfileDsl < Dsl
  
      attr_accessor :file_path, :bundler_enabled
      
      class << self
        alias :overriden_create :create
        def create(jarfile)
          builder = new
          builder.file_path = jarfile
          
          evaluate(builder, jarfile)
        end
      end

      def bundler(*groups)
        if groups.nil?
          groups = [:default]
        else
          groups = groups.map(&:to_sym)
        end

        @bundler_enabled = groups
      end
  
    end
  end
end