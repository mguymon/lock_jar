require "yaml"
require 'rubygems'
require 'lib/lock_jar/resolver'
require 'lib/lock_jar/dsl'
require 'lib/lock_jar/runtime'

module LockJar
  class Runtime
    def initialize( opts = {} )
      @resolver = LockJar::Resolver.new( opts )
    end
    
    def lock( jarfile, opts = {} )
        lock_jar_file = LockJar::Dsl.evaluate( jarfile )
    
        lock_jar_file.repositories.each do |repo|
          @resolver.add_remote_repository( repo )
        end
    
        lock_data = { 'scopes' => {} }
    
        if lock_jar_file.repositories.size > 0
          lock_data['repositories'] = lock_jar_file.repositories
        end
          
        lock_jar_file.notations.each do |scope, notations|
          
          dependencies = []
          notations.each do |notation|
            dependencies << {notation => scope}
          end
          
          resolved_notations = @resolver.resolve( dependencies )
          lock_data['scopes'][scope] = { 
            'dependencies' => notations,
            'resolved_dependencies' => resolved_notations } 
        end
    
        File.open( opts[:jarfile] || "Jarfile.lock", "w") do |f|
          f.write( lock_data.to_yaml )
        end
      end
    
      def list( jarfile_lock, scopes = ['compile', 'runtime'] )
        lock_data = YAML.load_file( jarfile_lock )
                
        dependencies = []
          
        scopes.each do |scope|
          dependencies += lock_data['scopes'][scope]['resolved_dependencies']
        end
        
        dependencies
      end
      
      def load( jarfile_lock, scopes = ['compile', 'runtime'] )
        lock_data = YAML.load_file( jarfile_lock )
        
        dependencies = []
           
        scopes.each do |scope|
          if lock_data['scopes'][scope]
            dependencies += lock_data['scopes'][scope]['resolved_dependencies']
          end
        end
        
        @resolver.load_jars_to_classpath( dependencies )
      end
  end
end