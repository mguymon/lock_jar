module Bundler
  class << self
    alias :_lockjar_extended_require :require
    def require(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_require
    end

    alias :_lockjar_extended_setup :setup
    def setup(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_setup
    end
  end

  class Runtime

    alias :_lockjar_extended_require :require
    def require(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_require
    end

    alias :_lockjar_extended_setup :setup
    def setup(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_setup
    end
  end

  class Definition
    alias :_lockjar_extended_to_lock :to_lock
    def to_lock
      to_lock = _lockjar_extended_to_lock

      if LockJar::Bundler.skip_lock != true
        definition = Bundler.definition
        #if !definition.send( :nothing_changed? )
        gems_with_jars = []

        # load local Jarfile
        if File.exists?( 'Jarfile' )
          dsl = LockJar::Domain::JarfileDsl.create( File.expand_path( 'Jarfile' ) )
          gems_with_jars << 'jarfile:Jarfile'
          # Create new Dsl
        else
          dsl = LockJar::Domain::Dsl.new
        end

        definition.groups.each do |group|
          if ENV["DEBUG"]
            puts "[LockJar] Group #{group}:"
          end

          definition.specs_for( [group] ).each do |spec|
            gem_dir = spec.gem_dir

            jarfile = File.join( gem_dir, "Jarfile" )

            if File.exists?( jarfile )
              gems_with_jars << "gem:#{spec.name}"

              if ENV["DEBUG"]
                puts "[LockJar]   #{spec.name} has Jarfile"
              end

              spec_dsl = LockJar::Domain::GemDsl.create( spec, "Jarfile" )

              dsl = LockJar::Domain::DslHelper.merge( dsl, spec_dsl, group.to_s )
            end
          end

        end

        puts "[LockJar] Locking Jars for: #{gems_with_jars.inspect}"
        LockJar.lock( dsl )
        #elsif ENV["DEBUG"]
        #  puts "[LockJar] Locking skiped, Gemfile has not changed"
        #end
      end

      to_lock
    end

  end
end