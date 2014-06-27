require 'lock_jar/registry'
require 'lock_jar_bundler/version'

module LockJar

  class Bundler

    def self.bundled_jarfiles(groups=[:default])
      jarfiles = []

      ::Bundler.with_clean_env do
        ::Bundler.setup(groups)
        definition = ::Bundler.definition

        definition.specs_for(groups).each do |spec|
          gem_dir = spec.gem_dir

          jarfile = File.join( gem_dir, "Jarfile" )

          # XXX: assert that is a LockJar file

          if File.exists?( jarfile )
            puts "#{spec.name} has Jarfile for locking"
            jarfiles << jarfile
          end
        end
      end

      jarfiles
    end

  end

end

