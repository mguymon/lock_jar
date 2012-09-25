require 'lock_jar'
require 'naether'

module LockJar
  class ClassLoader
    def initialize( lockfile )
      # XXX: ensure Naether has been loaded, this should be handled less
      #     clumsily
      LockJar::Runtime.instance.resolver(nil)
      @class_loader = com.tobedevoured.naether.PathClassLoader.new
      
      jars = LockJar.list( lockfile, :local_paths => true )
      jars.each do |jar|
        @class_loader.addPath( jar )
      end      
    end
    
    def isolate(&blk)    
      instance_eval(&blk)      
    end
    
    def create( clazz, *args )
      @class_loader.newInstance( clazz, *args )      
    end
  end
end