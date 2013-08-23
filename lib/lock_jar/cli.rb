require 'rubygems'
require 'thor'
require 'lock_jar'

module LockJar
  
  class CLI < Thor
    
    module ClassMethods
      def generate_lockfile_option
        method_option :lockfile, 
          :aliases => "-l", 
          :default => 'Jarfile.lock', 
          :desc => "Path to Jarfile.lock"
      end
      
      def generate_scopes_option
        method_option :scopes, 
          :aliases => "-s", 
          :default => ['default'],
          :desc => "Scopes to install from Jarfile.lock",
          :type => :array
      end
      
      def generate_jarfile_option
        method_option :jarfile,
          :aliases => "-j", 
          :default => 'Jarfile', 
          :desc => "Path to Jarfile"
      end
    end
    extend(ClassMethods)
    
    desc "version", "LockJar version"
    def version
      puts LockJar::VERSION
    end
    
    desc "install", "Install Jars from a Jarfile.lock"
    generate_lockfile_option
    generate_scopes_option
    def install
        puts "Installing Jars from #{options[:lockfile]} for #{options[:scopes].inspect}"
        LockJar.install( options[:lockfile], options[:scopes] )      
    end
    
    desc "list", "List Jars from a Jarfile.lock"
    generate_lockfile_option
    generate_scopes_option
    def list
      puts "Listing Jars from #{options[:lockfile]} for #{options[:scopes].inspect}"
      puts LockJar.list( options[:lockfile], options[:scopes] ).inspect
    end
    
    desc 'lock', 'Lock Jars in a Jarfile.lock'
    generate_jarfile_option
    generate_lockfile_option
    def lock
      puts "Locking #{options[:jarfile]} to #{options[:lockfile]}"
      LockJar.lock( options[:jarfile], { :lockfile => options[:lockfile] } )
    end
    
  end
end
