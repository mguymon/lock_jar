require 'lock_jar'

module LockJar
  class CLI
    
    def self.output
      @@output
    end
    
    def self.process( args )
      if args.length > 0
        args.each do|arg|
          matches = /^([a-z]+)(\[(.+)\])?/i.match(arg)
          if matches[1] == 'lock'
            
            jarfile = matches[3] || 'Jarfile'
            
            LockJar.lock( jarfile )
            
            puts "Jarfile.lock created from #{jarfile}"
            
          elsif matches[1] == "list"
            
            lockfile = matches[3] || 'Jarfile.lock'
            
            puts "Listing #{lockfile} jars for scopes compile, runtime"
            @@output = LockJar.list(lockfile).inspect
            
            puts @@output
          end
        end
      else
        puts "Arguments: lock[path to Jarfile] or list[path to Jarfile.lock]"
      end
    end
  end
end