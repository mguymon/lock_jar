require 'rubygems'
require 'naether'
require 'tmpdir'

class Accelr
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
    
    if opts[:offline]
      @naether.clear_remote_repositories
    end
  end
  
  def load( notations )
    @naether.dependencies = notations
    @naether.resolve_dependencies
    @naether.load_dependencies_to_classpath
  end

  def create( java_class, *args )
    Naether::Java.create( java_class, *args )
  end
end