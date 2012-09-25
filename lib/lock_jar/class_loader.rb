require 'naether'

module LockJar
  class ClassLoader
    def initialize( lockfile )
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