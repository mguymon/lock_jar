
class LockJar::Registry
    include Singleton
    
    attr_accessor :loaded_gems
    attr_accessor :loaded_jars
    attr_accessor :checked_filenames
    
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
    
    def load_jars_for_gems      
      specs = Gem.loaded_specs
      if specs 
        gems_to_check = specs.keys - @loaded_gems.keys
        if gems_to_check.size > 0
          @loaded_gems.replace( specs )
          
          gems_to_check.each do |key|
            spec = specs[key]
            
            gem_dir = spec.gem_dir
     		
            lockfile = File.join( gem_dir, "Jarfile.lock" )
           	
            if File.exists?( lockfile )
           	  puts "#{key} #{spec.name} has Jarfile.lock, loading jars"
              LockJar.load( lockfile )
            end  
          end 
        end
      end
    end

end