module LockJar
  #
  class Runtime
    #
    module Load
      # Load paths from a lockfile or block. Paths are loaded once per lockfile.
      #
      # @param [String] lockfile_path the lockfile
      # @param [Array] groups to load into classpath
      # @param [Hash] opts
      # @param [Block] blk
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def load(lockfile_or_path, groups = ['default'], opts = {}, &blk)
        # lockfile is only loaded once
        unless lockfile_or_path.nil?
          # loaded a Lockfile instance
          if lockfile_or_path.is_a? LockJar::Domain::Lockfile
            lockfile = lockfile_or_path

          else
            # check if lockfile path is already loaded
            return if LockJar::Registry.instance.lockfile_registered?(lockfile_or_path)

            # convert lockfile path to a Lockfile instance
            lockfile = LockJar::Domain::Lockfile.read(lockfile_or_path)
          end

          if opts[:local_repo].nil? && lockfile.local_repository
            opts[:local_repo] = lockfile.local_repository
          end
        end

        # set local_repo if passed in the block
        unless blk.nil?
          dsl = LockJar::Domain::Dsl.create(&blk)

          # set local_repo from block
          opts[:local_repo] = dsl.local_repository if opts[:local_repo].nil? && dsl.local_repository
        end

        # registered merged lockfiles for lockfile
        if lockfile && !lockfile.merged.empty?
          lockfile.merged.each { |path| LockJar::Registry.instance.register_lockfile(path) }
        end

        dependencies = LockJar::Registry.instance.register_jars(list(lockfile, groups, opts, &blk))

        resolver(opts).load_to_classpath(dependencies)
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
