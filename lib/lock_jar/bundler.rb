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
      # Create a lock file from bundled gems
      #
      # rubocop:disable Metrics/PerceivedComplexity
      def lock!(bundler, *opts)
        return unless bundler.instance_variable_get('@setup').nil?

        dsl = nil

        jarfile_opt = opts.find { |option| option.is_a? String }

        jarfile = File.expand_path(jarfile_opt || 'Jarfile')

        # load local Jarfile
        if File.exist?(jarfile)
          dsl = LockJar::Domain::JarfileDsl.create(jarfile)

        # Create new Dsl
        else
          dsl = LockJar::Domain::Dsl.new
        end

        gems_with_jars = []
        ::Bundler.definition.groups.each do |group|
          puts "[LockJar] Group #{group}:" if ENV['DEBUG']

          ::Bundler.definition.specs_for([group]).each do |spec|
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
      # rubocop:enable Metrics/PerceivedComplexity

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
