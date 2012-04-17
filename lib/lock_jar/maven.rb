require 'lock_jar/runtime'

module LockJar
  class Maven
    
    class << self
      
      def pom_version( pom_path, opts = {} )
        Runtime.instance.resolver(opts).naether.pom_version( pom_path )
      end
      
      def write_pom( notation, file_path, opts = {} )
        Runtime.instance.resolver(opts).naether.write_pom( notation, file_path )
      end
      
      def deploy_artifact( notation, file_path, url, deploy_opts = {}, lockjar_opts = {} )
        Runtime.instance.resolver(lockjar_opts).naether.deploy_artifact( notation, file_path, url, deploy_opts )
      end
      
      def install( notation, pom_path, jar_path, opts = {} )
        Runtime.instance.resolver(opts).naether.install( notation, pom_path, jar_path )
      end
    end
  end
end