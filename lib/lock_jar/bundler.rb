require 'lock_jar'
require 'lock_jar/registry'
require 'lock_jar/domain/dsl'
require 'lock_jar/domain/gem_dsl'
require 'lock_jar/domain/dsl_helper'

module LockJar
  
  module Bundler
    
  end
  
end

module Bundler
  class << self
    alias :_lockjar_extended_require :require
    def require(*groups)
      if File.exists?( 'Jarfile.lock')
        LockJar.load(groups)
        
        if ENV["DEBUG"]
          puts "[LockJar] Loaded Jars: #{LockJar::Registry.instance.loaded_jars.inspect}"
        end
      end
      
      _lockjar_extended_require
    end
    
    alias :_lockjar_extended_setup :setup
    def setup(*groups)
      if File.exists?( 'Jarfile.lock')
        LockJar.load(groups)
      end
      
      if ENV["DEBUG"]
        puts "[LockJar] Loaded Jars: #{LockJar::Registry.instance.loaded_jars.inspect}"
      end
      
      _lockjar_extended_setup
    end
  end
  
  class Definition
    alias :_lockjar_extended_to_lock :to_lock
    def to_lock
      to_lock = _lockjar_extended_to_lock
   
      definition = Bundler.definition
      if !definition.send( :nothing_changed? )
        # load local Jarfile
        if File.exists?( 'Jarfile' )
          dsl = LockJar::Domain::Dsl.create( 'Jarfile' )
        
        # Create new Dsl
        else
          dsl = LockJar::Domain::Dsl.new
        end
        
        gems_with_jars = []
        definition.groups.each do |group|
          if ENV["DEBUG"]
            puts "[LockJar] Group #{group}:"
          end
            
          definition.specs_for( [group] ).each do |spec|
            gem_dir = spec.gem_dir
    		
            jarfile = File.join( gem_dir, "Jarfile" )
           	
            if File.exists?( jarfile )
              gems_with_jars << spec.name
           	  
              if ENV["DEBUG"]
                puts "[LockJar]   #{spec.name} has Jarfile"
              end
              
              spec_dsl = LockJar::Domain::GemDsl.create( gem_dir, "Jarfile" )
              
              dsl = LockJar::Domain::DslHelper.merge( dsl, spec_dsl )
            end 
          end
          
        end
  
        puts "[LockJar] Locking Jars for Gems: #{gems_with_jars.inspect}"
        LockJar.lock(dsl, :gems => gems_with_jars )
      elsif ENV["DEBUG"]
        puts "[LockJar] Locking skiped, Gemfile has not changed"
      end      
      to_lock
    end
    
  end
end