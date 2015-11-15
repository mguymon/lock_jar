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

require 'lock_jar'
require 'naether'

module LockJar
  #
  # Create a ClassLoader populated by a lockfile
  #
  # @author Michael Guymon
  #
  class ClassLoader
    # Create new instance, populating ClassLoader with lockfile
    #
    # @param [String] lockfile path
    def initialize(lockfile)
      # XXX: ensure Naether has been loaded, this should be handled less
      #     clumsily
      LockJar::Runtime.instance.resolver(nil)
      @class_loader = com.tobedevoured.naether.PathClassLoader.new(
        JRuby.runtime.jruby_class_loader)

      jars = LockJar.list(lockfile, local_paths: true)
      jars.each do |jar|
        add_path(jar)
      end
    end

    # Execute block
    #
    # @param [Block] blk
    def isolate(&blk)
      instance_eval(&blk)
    end

    # Add path to the ClassLoader
    #
    # @param [String] path of Jar or directory to add to ClassLoader
    # @return [Boolean] if added
    def add_path(path)
      @class_loader.addPath(path)
    end

    #
    # Create new instance of a Java class using the populated ClassLoader
    #
    # @param [String] clazz fully qualified Java class
    # @param [Array] args arguments for constructing the Java class
    # @return [Object]
    def new_instance(clazz, *args)
      @class_loader.newInstance(clazz, *args)
    end
  end
end
