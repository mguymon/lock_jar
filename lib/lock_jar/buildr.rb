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
require 'lock_jar/domain/dsl'

module Buildr
  
  @@global_lockjar_dsl = nil
  
  class << self
    def project_to_lockfile( project )
      "#{project.name.gsub(/:/,'-')}.lock"
    end
    
    def global_lockjar_dsl
      @@global_lockjar_dsl 
    end
  end
  
  def lock_jar( &blk )
    @@global_lockjar_dsl = ::LockJar::Domain::Dsl.create(&blk) 
  end
  
  namespace "lock_jar" do
    desc "Lock dependencies for each project"    
    task("lock") do 
      projects.each do |project|   
        if project.lockjar_dsl
          # add buildr repos
          repositories.remote.each do |repo|
            project.lockjar_dsl.repository repo
          end
          ::LockJar.lock( project.lockjar_dsl, :lockfile => Buildr.project_to_lockfile(project) )       
        end
      end
    end
  end
  
  module LockJar
    module ProjectExtension
      include Extension
    
      def lock_jar( &blk )
          @lockjar_dsl = ::LockJar::Domain::Dsl.create(&blk)    
                   
          unless Buildr.global_lockjar_dsl.nil?
            @lockjar_dsl.merge( Buildr.global_lockjar_dsl )
          end        
      end
      
      def lock_jars( *args )
        lockfile = Buildr.project_to_lockfile(project)
        opts = {}
        groups = ['default']
          
        args.each do |arg|
          if arg.is_a?(Hash)
            opts.merge!( arg )
          elsif arg.is_a?( String )
            lockfile = arg
          elsif arg.is_a?( Array )
            groups = arg
          end
        end
          
        ::LockJar.list( lockfile, groups, opts )
      end
      
      def lockjar_dsl
        @lockjar_dsl || Buildr.global_lockjar_dsl
      end
      
      after_define do |project|      
        task :compile => 'lock_jar:compile'
        task 'test:compile' => 'lock_jar:test:compile'
        
        task 'eclipse' => 'lock_jar:eclipse'
        
        namespace "lock_jar" do
            desc "Lock dependencies to JarFile"
            task("lock") do 
              dsl = project.lockjar_dsl
              if dsl
                # add buildr repos
                repositories.remote do |repo|
                  puts repo
                  dsl.repository repo
                end
                ::LockJar.lock( dsl, :lockfile => "#{project.name}.lock" )
              else
                # XXX: output that there were no dependencies to lock
                puts "No lock_jar dependencies to lock for #{project.name}" 
              end              
            end      
            
            task("compile") do
              if project.lockjar_dsl && !File.exists?( Buildr.project_to_lockfile(project) )
                raise "#{project.name}.lock does not exist, run #{project.name}:lockjar:lock first"
              end
              jars = ::LockJar.list( Buildr.project_to_lockfile(project), ['default'] )
              project.compile.with( jars )
            end
            
            task("test:compile") do
              if project.lockjar_dsl && !File.exists?( Buildr.project_to_lockfile(project) )
                raise "#{Buildr.project_to_lockfile(project)} does not exist, run #{project.name}:lockjar:lock first"
              end
              jars = ::LockJar.list( Buildr.project_to_lockfile(project), ['test'] )
              
              project.test.compile.with( jars )
              project.test.with( jars )
            end
            
            task("eclipse") do
              if project.lockjar_dsl && !File.exists?( Buildr.project_to_lockfile(project) )
                raise "#{Buildr.project_to_lockfile(project)} does not exist, run #{project.name}:lockjar:lock first"
              end
              jars = ::LockJar.list( Buildr.project_to_lockfile(project), ['default'] )
              project.compile.with( jars )
              
              jars = ::LockJar.list( Buildr.project_to_lockfile(project), ['test'] )
              project.test.compile.with( jars )
            end
        end
      end
    end
  end
end

class Buildr::Project
  include Buildr::LockJar::ProjectExtension
end