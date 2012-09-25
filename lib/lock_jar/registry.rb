
class LockJar::Registry
    include Singleton
    
    attr_accessor :loaded_gems
    attr_accessor :loaded_jars
    
    def initialize
      @loaded_gems = {}
      @loaded_jars = []
    end
    
    def register_jars( jars )
      if jars
        jars_to_load = jars - @loaded_jars
        
        @loaded_jars += jars_to_load
        
        jars_to_load
      end
    end
    
    def load_gem( spec )
      if @loaded_gems[spec.name].nil?
        @loaded_gems[spec.name] = spec
        gem_dir = spec.gem_dir
  		
        lockfile = File.join( gem_dir, "Jarfile.lock" )
       	
        if File.exists?( lockfile )
       	  puts "#{spec.name} has Jarfile.lock, loading jars"
          LockJar.load( lockfile )
        end 
      end
    end
    
    def load_jars_for_gems      
      specs = Gem.loaded_specs
      if specs 
        gems_to_check = specs.keys - @loaded_gems.keys
        if gems_to_check.size > 0
          gems_to_check.each do |key|
            spec = specs[key]
            load_gem( spec )
          end 
        end
      end
    end

end