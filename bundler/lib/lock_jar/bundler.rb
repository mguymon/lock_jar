require "lock_jar/bundler/version"

module LockJar

  class Bundler

    class << self

      attr_accessor :skip_lock

      def load(*groups)
        if groups && !groups.empty?  && File.exists?( 'Jarfile.lock')

          lockfile = LockJar::Domain::Lockfile.read( 'Jarfile.lock' )

          # expand merged paths to include gem base path
          unless lockfile.merged.empty?
            lockfile.merged = LockJar::Bundler.expand_gem_paths( lockfile.merged )
          end

          LockJar.load( lockfile, groups )

          if ENV["DEBUG"]
            puts "[LockJar] Loaded Jars for #{groups.inspect}: #{LockJar::Registry.instance.loaded_jars.inspect}"
          end
        end
      end

      def expand_gem_paths(merged)

        merged_gem_paths = []
        Gem.path.each do |gem_root|
          merged.each do |merge|
            # merged gems follow the notation: gem:gemname:path
            if merge.start_with? 'gem:'
              gem_path = merge.gsub(/^gem:.+:/, '')
              gem_path = File.join( gem_root, gem_path )
              if File.exists? gem_path
                merged_gem_paths << gem_path
              end
            end
          end
        end

        merged_gem_paths
      end
    end
  end

end

