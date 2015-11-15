module LockJar
  #
  class Runtime
    #
    module Install
      def install(jarfile_lock, groups = ['default'], opts = {}, &blk)
        deps = list(jarfile_lock, groups, { with_locals: false }.merge(opts), &blk)

        lockfile = LockJar::Domain::Lockfile.read(jarfile_lock)
        if opts[:local_repo].nil? && lockfile.local_repository
          opts[:local_repo] = lockfile.local_repository
        end

        # Older Jarfile expected the defaul maven repo, but did not write
        # it to the lockfile
        resolver(opts).clear_remote_repositories if lockfile.version.to_f >= 0.11

        lockfile.remote_repositories.each do |repo|
          resolver(opts).add_remote_repository(repo)
        end

        files = resolver(opts).download(deps)

        files
      end
    end
  end
end
