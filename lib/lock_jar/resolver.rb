require 'rubygems'
require 'naether'

module LockJar
  class Resolver
    
    attr_reader :naether
    
    def initialize( opts = {} )
      local_repo = opts[:local_repo]
      
      # Bootstrap Naether
      jars = []
      deps = Naether::Bootstrap.check_local_repo_for_deps( local_repo )
      if deps[:missing].size > 0
        Dir.mktmpdir do |dir|
          deps = Naether::Bootstrap.download_dependencies( dir, deps.merge( :local_repo => local_repo ) )
          if deps[:downloaded].size > 0
            Naether::Bootstrap.install_dependencies_to_local_repo( dir, :local_repo => local_repo )
            jars = deps[:downloaded].map{ |jar| jar.values[0] }
          else
            # XXX: download failed?
          end
        end
      else
        jars = deps[:exists].map{ |jar| jar.values[0] }
      end
      
      jars << Naether::JAR_PATH
      @naether = Naether.create_from_jars( jars )
      
      @naether.local_repo_path = opts[:local_repo] if opts[:local_repo]
      
      
      @naether.clear_remote_repositories if opts[:offline]
    end
    
    def add_remote_repository( repo )
      @naether.add_remote_repository( repo )
    end
    
    def resolve( notations )
      @naether.dependencies = notations
      @naether.resolve_dependencies
      @naether.dependencies_path
    end
    
    def load_jars_to_classpath( jars )
      
    end
  end
end