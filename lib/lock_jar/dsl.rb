module LockJar
  class Dsl
    def self.evaluate(jarfile)
      builder = new
      builder.instance_eval(builder.read_file(jarfile.to_s), jarfile.to_s, 1)
      #builder.to_definition(lockfile, unlock)
      
      builder
    end
    
    attr_reader :notations
    attr_reader :repositories
    
    def initialize
      @notations = []
      @repositories = []
    end
    
    def jar(notation, *args)
      @notations << notation
    end
    
    def repository( url, opts = {} )
      @repositories << url
    end
    
    def scope(*scope)
       yield
    end
    
    def read_file(file)
      File.open(file, "rb") { |f| f.read }
    end
    
  end
end