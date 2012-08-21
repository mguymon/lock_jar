require 'lock_jar'

module LockJar
  class CLI
    def self.process( args )
      if args.length > 0
        args.each do|arg|
          if arg == "lock"
            LockJar.lock
            puts "Jarfile.lock created"
          elsif arg == "list"
            puts "Listing Jarfile.lock jars for scopes compile, runtime"
            puts LockJar.list.inspect
          end
        end
      else
        puts "Arguments: lock, load, or list"
      end
    end
  end
end