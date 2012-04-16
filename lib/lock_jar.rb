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

require "yaml"
require 'rubygems'
require 'lock_jar/resolver'
require 'lock_jar/dsl'
require 'lock_jar/runtime'

module LockJar
  
  def self.lock( jarfile = 'Jarfile', opts = {} )
    Runtime.new( opts ).lock( jarfile, opts )
  end
  
  def self.list( lockfile = 'Jarfile.lock', scopes = ['compile', 'runtime'], opts = {} )
      Runtime.new( opts ).list( lockfile, scopes )
  end
    
  def self.load( lockfile = 'Jarfile.lock', scopes = ['compile', 'runtime'], opts = {} )
      Runtime.new( opts ).load( lockfile, scopes )
  end

end