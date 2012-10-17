require 'lock_jar'
require 'lock_jar/registry'
require 'lock_jar/domain/lockfile'
require 'lock_jar/domain/dsl'
require 'lock_jar/domain/gem_dsl'
require 'lock_jar/domain/jarfile_dsl'
require 'lock_jar/domain/dsl_helper'

module LockJar
  
  class Bundler
      
    class << self
      
      attr_accessor :skip_lock
    
      def load(*groups)
        if groups && !groups.empty?  && File.exists?( 'Jarfile.lock')
          
          lockfile = LockJar::Domain::Lockfile.read( 'Jarfile.lock' )
          
          # expand merged paths to include gem base path
          unless lockfile.merged.empty?
            lockfile.merged = LockJar::Bundler.expand_gem_paths( lockfile.merged )
          end
          
          LockJar.load( lockfile, groups )
          
          if ENV["DEBUG"]
            puts "[LockJar] Loaded Jars for #{groups.inspect}: #{LockJar::Registry.instance.loaded_jars.inspect}"
          end
        end
      end
      
      def expand_gem_paths(merged)
        
        merged_gem_paths = []
        Gem.path.each do |gem_root|
          merged.each do |merge|
            # merged gems follow the notation: gem:gemname:path
            if merge.start_with? 'gem:'
              gem_path = merge.gsub(/^gem:.+:/, '')
              gem_path = File.join( gem_root, gem_path )
              if File.exists? gem_path
                merged_gem_paths << gem_path
              end
            end
          end
        end
        
        merged_gem_paths
      end
    end
  end
  
end

module Bundler
  class << self
    alias :_lockjar_extended_require :require
    def require(*groups)
      LockJar::Bundler.load(*groups)
      
      LockJar::Bundler.skip_lock = true
      
      _lockjar_extended_require
    end
    
    alias :_lockjar_extended_setup :setup
    def setup(*groups)
      LockJar::Bundler.load(*groups)
      
      LockJar::Bundler.skip_lock = true
      
      _lockjar_extended_setup
    end
  end
  
  class Runtime
    
    alias :_lockjar_extended_require :require
    def require(*groups)
      LockJar::Bundler.load(*groups)
      
      LockJar::Bundler.skip_lock = true
      
      _lockjar_extended_require
    end
    
    alias :_lockjar_extended_setup :setup
    def setup(*groups)
      LockJar::Bundler.load(*groups)
      
      LockJar::Bundler.skip_lock = true
      
      _lockjar_extended_setup
    end
  end
  
  class Definition
    alias :_lockjar_extended_to_lock :to_lock
    def to_lock
      to_lock = _lockjar_extended_to_lock
   
      if LockJar::Bundler.skip_lock != true
        definition = Bundler.definition
        #if !definition.send( :nothing_changed? )
          gems_with_jars = []
          
          # load local Jarfile
          if File.exists?( 'Jarfile' )
            dsl = LockJar::Domain::JarfileDsl.create( File.expand_path( 'Jarfile' ) )
            gems_with_jars << 'jarfile:Jarfile'
          # Create new Dsl
          else
            dsl = LockJar::Domain::Dsl.new
          end
          
          definition.groups.each do |group|
            if ENV["DEBUG"]
              puts "[LockJar] Group #{group}:"
            end
              
            definition.specs_for( [group] ).each do |spec|
              gem_dir = spec.gem_dir
      		
              jarfile = File.join( gem_dir, "Jarfile" )
             	
              if File.exists?( jarfile )
                gems_with_jars << "gem:#{spec.name}"
             	  
                if ENV["DEBUG"]
                  puts "[LockJar]   #{spec.name} has Jarfile"
                end
                
                spec_dsl = LockJar::Domain::GemDsl.create( spec, "Jarfile" )
                
                dsl = LockJar::Domain::DslHelper.merge( dsl, spec_dsl, group.to_s )
              end 
            end
            
          end
    
          puts "[LockJar] Locking Jars for: #{gems_with_jars.inspect}"
          LockJar.lock( dsl )
        #elsif ENV["DEBUG"]
        #  puts "[LockJar] Locking skiped, Gemfile has not changed"
        #end   
      end
      
      to_lock
    end
    
  end
end