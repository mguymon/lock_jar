require 'rubygems'
require 'lib/lock_jar/resolver'
require 'lib/lock_jar/dsl'

module LockJar
  def self.lock( jarfile, opts = {} )
    # load notations from Jarfile
    # resolve dependencies
    # create Jarfile.lock

    resolver = LockJar::Resolver.new( opts )
    lock_jar_file = LockJar::Dsl.evaluate( jarfile )

    lock_jar_file.repositories.each do |repo|
      resolver.add_remote_repository( repo )
    end
    resolved_notations = resolver.resolve( lock_jar_file.notations )

    lock_data = {}
    
    if lock_jar_file.repositories.size > 0
      lock_data['repositories'] = lock_jar_file.repositories 
    end
    lock_data['dependencies'] = resolved_notations
    
    File.open("Jarfile.lock", "w") do |f|
      f.write( lock_data.to_yaml )
    end
  end

  def self.load( jarfile_lock )
    # load Jarfile.lock
    # create path to jars
    # manually add to class path?
  end

end