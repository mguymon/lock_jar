module LockJar
  #
  class Runtime
    #
    module List
      def list(lockfile_or_path, groups = ['default'], opts = {}, &blk)
        lockfile = nil
        dependencies = []
        maps = []
        with_locals = { with_locals: true }.merge(opts).delete(:with_locals)

        if lockfile_or_path
          if lockfile_or_path.is_a? LockJar::Domain::Lockfile
            lockfile = lockfile_or_path
          elsif lockfile_or_path
            lockfile = LockJar::Domain::Lockfile.read(lockfile_or_path)
          end

          dependencies = lockfile_dependencies(lockfile, groups, with_locals)
          maps = lockfile.maps
        end

        # Support limited DSL from block
        unless blk.nil?
          dsl = LockJar::Domain::Dsl.create(&blk)
          dependencies += dsl_dependencies(dsl, groups, with_locals).map(&:to_dep)
          maps = dsl.maps
        end

        if maps && maps.size > 0
          maps.each do |notation, replacements|
            dependencies = dependencies.flat_map do |dep|
              if dep =~ /#{notation}/
                replacements
              else
                dep
              end
            end
          end
        end

        dependencies = resolver(opts).resolve(dependencies) if opts[:resolve]

        if opts[:local_paths]
          opts.delete(:local_paths) # remove list opts so resolver is not reset
          resolver(opts).to_local_paths(dependencies)

        else
          dependencies
        end
      end
    end
  end
end
