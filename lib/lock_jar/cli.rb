require 'lock_jar'

module LockJar
  class CLI
    def self.process
      if ARGV.length > 0
        ARGV.each do|arg|
          if arg == "lock"
            LockJar.lock
          elsif arg == "load"
            LockJar.load
          elsif arg == "list"
            LockJar.list
          end
        end
      else
        puts "Arguments: lock, load, or list"
      end
    end
  end
end