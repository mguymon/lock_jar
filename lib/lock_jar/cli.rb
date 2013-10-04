require 'rubygems'
require 'thor'
require 'lock_jar'

module LockJar

  # Maven subcommand
  class MavenCLI < Thor

    module ClassMethods
      def generate_pom_option
        method_option :pom,
                      :aliases => '-p',
                      :default => 'pom.xml',
                      :desc => 'Path to pom.xml'
      end

      def generate_maven_home_option
        method_option :maven_home,
                      :aliases => '-m',
                      :desc => 'Path to installed Maven'
      end
    end
    extend(ClassMethods)

    desc 'goal', 'invoke Maven goals'
    generate_pom_option
    generate_maven_home_option
    def goal(*goals)
      opts = {}
      opts[:maven_home] = options[:maven_home] if options[:maven_home]

      Runtime.instance.resolver

      puts "Invoking #{goals.join(' ')} on #{options[:pom]}"
      LockJar::Maven.invoke(options[:pom], goals, opts)
    end

    desc 'uberjar', 'Create uberjar from Maven POM'
    method_option :jarfile,
                  :aliases => '-j',
                  :default => 'Jarfile',
                  :desc => 'Path to Jarfile'
    generate_maven_home_option
    method_option :force,
                  :aliases => '-f',
                  :type => :boolean,
                  :desc => 'Force the building of the Uberjar, even if nothing changed'
    method_option :package,
                  :aliases => '-k',
                  :type => :boolean,
                  :desc => 'Eexecute the Maven package goal before building'
    method_option :assembly_dir,
                  :aliases => '-a',
                  :desc => 'Directory where the uberjar is assembled'
    method_option :destination_dir,
                  :aliases => '-d',
                  :desc => 'Directory where the uberjar jar is created'
    def uberjar
      opts = {}
      opts[:maven_home] = options[:maven_home] if options[:maven_home]
      opts[:force] = options[:force] if options[:force]
      opts[:package] = options[:package] if options[:package]
      opts[:assembly_dir] = options[:assembly_dir] if options[:assembly_dir]
      opts[:destination_dir] = options[:destination_dir] if options[:destination_dir]

      jarfile = options[:jarfile]
      dsl = LockJar::Domain::Dsl.create(jarfile)
      begin
        LockJar::Maven.uberjar(dsl.pom, opts)
      rescue => exception
        puts exception.backtrace
      end
    end

  end

  # Main command
  class CLI < Thor
    
    module ClassMethods
      def generate_lockfile_option
        method_option :lockfile,
          :aliases => '-l',
          :default => 'Jarfile.lock',
          :desc => 'Path to Jarfile.lock'
      end

      def generate_scopes_option
        method_option :scopes,
          :aliases => '-s',
          :default => ['default'],
          :desc => 'Scopes to install from Jarfile.lock',
          :type => :array
      end

      def generate_jarfile_option
        method_option :jarfile,
          :aliases => '-j',
          :default => 'Jarfile',
          :desc => 'Path to Jarfile'
      end
    end
    extend(ClassMethods)

    desc 'version', 'LockJar version'
    def version
      puts LockJar::VERSION
    end

    desc 'install', 'Install Jars from a Jarfile.lock'
    generate_lockfile_option
    generate_scopes_option
    def install
        puts "Installing Jars from #{options[:lockfile]} for #{options[:scopes].inspect}"
        LockJar.install( options[:lockfile], options[:scopes] )
    end

    desc 'list', 'List Jars from a Jarfile.lock'
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

    desc 'maven', 'Run tasks on a Maven POM'
    subcommand "maven", LockJar::MavenCLI
    
  end
end
