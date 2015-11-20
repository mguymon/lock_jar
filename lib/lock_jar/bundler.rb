require 'lock_jar'
require 'lock_jar/registry'
require 'lock_jar/domain/lockfile'
require 'lock_jar/domain/dsl'
require 'lock_jar/domain/gem_dsl'
require 'lock_jar/domain/jarfile_dsl'
require 'lock_jar/domain/dsl_merger'

module LockJar
  #
  class Bundler
    class << self
      attr_accessor :skip_lock

      def load(*groups)
        return if groups.empty? || !File.exist?('Jarfile.lock')

        lockfile = LockJar::Domain::Lockfile.read('Jarfile.lock')

        # expand merged paths to include gem base path
        unless lockfile.merged.empty?
          lockfile.merged = LockJar::Bundler.expand_gem_paths(lockfile.merged)
        end

        LockJar.load(lockfile, groups)

        puts(
          '[LockJar] Loaded Jars for #{groups.inspect}: '\
          "#{LockJar::Registry.instance.loaded_jars.inspect}"
        ) if ENV['DEBUG']
      end

      def expand_gem_paths(merged)
        merged_gem_paths = []
        Gem.path.each do |gem_root|
          merged.each do |merge|
            next unless merge.start_with? 'gem:'

            # merged gems follow the notation: gem:gemname:path
            gem_path = merge.gsub(/^gem:.+:/, '')
            gem_path = File.join(gem_root, gem_path)

            merged_gem_paths << gem_path if File.exist? gem_path
          end
        end

        merged_gem_paths
      end

      # Create a lock file from bundled gems
      def lock!(*opts)
        definition = ::Bundler.definition

        dsl = nil
        gems_with_jars = []

        jarfile_opt = opts.find { |option| option.is_a? String }

        jarfile = File.expand_path(jarfile_opt || 'Jarfile')

        # load local Jarfile
        if File.exist?(jarfile)
          dsl = LockJar::Domain::JarfileDsl.create(jarfile)

        # Create new Dsl
        else
          dsl = LockJar::Domain::Dsl.new
        end

        definition.groups.each do |group|
          puts "[LockJar] Group #{group}:" if ENV['DEBUG']

          definition.specs_for([group]).each do |spec|
            next unless File.exist? File.join(spec.gem_dir, 'Jarfile')

            merged_dsl = merge_gem_dsl(dsl, spec, group)
            if merged_dsl
              gems_with_jars << "gem:#{spec.name}"
              dsl = merged_dsl
            end
          end
        end

        puts "[LockJar] Locking Jars for: #{gems_with_jars.inspect}"
        LockJar.lock(*([dsl] + opts))
      end

      private

      def merge_gem_dsl(dsl, spec, group)
        jarfile = File.join(spec.gem_dir, 'Jarfile')

        return unless File.exist?(jarfile)

        puts "[LockJar]   #{spec.name} has Jarfile" if ENV['DEBUG']
        spec_dsl = LockJar::Domain::GemDsl.create(spec, jarfile)
        LockJar::Domain::DslMerger.new(dsl, spec_dsl, [group.to_s]).merge
      end
    end
  end
end

# Patch Bundler module to allow LockJar to lock and load when Bundler is run
module Bundler
  class << self
    alias_method :_lockjar_extended_require, :require
    def require(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_require
    end

    alias_method :_lockjar_extended_setup, :setup
    def setup(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_setup
    end
  end

  # Patch Bundler::Runtime.require and Bundler::Runtime.setup to execute
  # Lockjar::Bundler.load
  class Runtime
    alias_method :_lockjar_extended_require, :require
    def require(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_require
    end

    alias_method :_lockjar_extended_setup, :setup
    def setup(*groups)
      LockJar::Bundler.load(*groups)

      LockJar::Bundler.skip_lock = true

      _lockjar_extended_setup
    end
  end

  # Patch Bundler::Definition.to_lock to run LockJar::Bundler.lock!
  class Definition
    alias_method :_lockjar_extended_to_lock, :to_lock
    def to_lock
      result = _lockjar_extended_to_lock

      return result if LockJar::Bundler.skip_lock

      LockJar::Bundler.lock!

      result
    end
  end
end
