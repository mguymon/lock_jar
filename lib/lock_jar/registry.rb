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

require 'singleton'

module LockJar
  #
  # Registry of resources loaded by LockJar
  #
  # @author Michael Guymon
  #
  class Registry
    include Singleton

    attr_accessor :loaded_gems, :loaded_jars, :loaded_lockfiles

    def initialize
      @loaded_gems = {}
      @loaded_jars = []
      @loaded_lockfiles = []
    end

    def lockfile_registered?(lockfile)
      @loaded_lockfiles.include? File.expand_path(lockfile) if lockfile
    end

    def register_lockfile(lockfile)
      return if lockfile.nil? || lockfile_registered?(lockfile)

      @loaded_lockfiles << File.expand_path(lockfile)
    end

    def register_jars(jars)
      return if jars.nil?

      jars_to_load = jars - @loaded_jars

      @loaded_jars += jars_to_load

      jars_to_load
    end

    def register_gem(spec)
      @loaded_gems[spec.name] = spec
    end

    def gem_registered?(spec)
      !@loaded_gems[spec.name].nil?
    end

    def load_gem(spec)
      return if gem_registered?(spec)

      register_gem(spec)
      gem_dir = spec.gem_dir

      lockfile = File.join(gem_dir, 'Jarfile.lock')

      return unless File.exist?(lockfile)

      puts "#{spec.name} has Jarfile.lock, loading jars"
      LockJar.load(lockfile)
    end

    def load_jars_for_gems
      specs = Gem.loaded_specs
      return if specs.nil?

      gems = specs.keys - @loaded_gems.keys
      gems.each { |key| load_gem(specs[key]) }
    end
  end
end
