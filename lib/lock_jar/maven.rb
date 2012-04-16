

module LockJar
  class Maven
    
    class << self
      def runtime( opts = {} )
        Runtime.new( opts )
      end
      
      def pom_version( pom_path, opts = {} )
        runtime(opts).resolver.naether.pom_version( pom_path )
      end
      
      def write_pom( notation, file_path, opts = {} )
        runtime(opts).resolver.naether.write_pom( notation, file_path )
      end
      
      def deploy_artifact( notation, file_path, url, deploy_opts = {}, lockjar_opts = {} )
        runtime(lockjar_opts).resolver.naether.deploy_artifact( notation, file_path, url, deploy_opts )
      end
      
      def install( notation, pom_path, jar_path, opts = {} )
        runtime(opts).resolver.naether.install( notation, pom_path, jar_path )
      end
    end
  end
end