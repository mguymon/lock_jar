require 'lock_jar/registry'

module LockJar::Rubygems
  module Kernel
    unless respond_to? :lock_jar_registry
      def lock_jar_registry
        LockJar::Registry.instance
      end
  
      alias :_pre_lockjar_require :require
  
      def require( filename )
        spec = Gem::Specification.find_by_path( filename )
        if spec
          lock_jar_registry.load_gem( spec )
        end
        _pre_lockjar_require( filename )
      end
    end
  end
end