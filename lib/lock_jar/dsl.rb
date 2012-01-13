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
    attr_reader :scopes
    
    def initialize

      @repositories = []
      @scopes = ['compile', 'runtime', 'test']
      @notations = {}
        
      @scopes.each do |scope|
        @notations[scope] = []
      end
        
      @present_scope = 'compile'
    end
    
    def jar(notation, *args)
      @notations[@present_scope] << notation
    end
    
    def repository( url, opts = {} )
      @repositories << url
    end
    
    def scope(*scopes, &blk)
       scopes.each do |scope|
         @present_scope = scope.to_s
         yield
       end
       
       @present_scope = 'compile'
    end
    
    def read_file(file)
      File.open(file, "rb") { |f| f.read }
    end
    
  end
end