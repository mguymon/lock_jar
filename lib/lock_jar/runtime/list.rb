module LockJar
  #
  class Runtime
    #
    module List
      # rubocop:disable Metrics/PerceivedComplexity, MethodLength
      def list(lockfile_or_path, groups = ['default'], opts = {}, &blk)
        dependencies = []
        maps = []
        with_locals = { with_locals: true }.merge(opts).delete(:with_locals)

        if lockfile_or_path
          lockfile = build_lockfile(lockfile_or_path)
          dependencies = dependencies_from_lockfile(lockfile, groups, with_locals, opts)
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

        # local_paths and !resolve are mutualally exclusive
        if opts[:local_paths] && opts[:resolve] != false
          # remove local_paths opt so resolver is not reset
          resolver(opts.reject { |k| k == :local_paths }).to_local_paths(dependencies)

        else
          dependencies
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity, MethodLength

      def build_lockfile(lockfile_or_path)
        if lockfile_or_path.is_a? LockJar::Domain::Lockfile
          lockfile_or_path
        elsif lockfile_or_path
          LockJar::Domain::Lockfile.read(lockfile_or_path)
        end
      end

      def dependencies_from_lockfile(lockfile, groups, with_locals, opts)
        # Only list root dependencies
        if opts[:resolve] == false
          lockfile_dependencies(lockfile, groups, with_locals) do |group|
            group['artifacts'].flat_map(&:keys).map do |notation|
              # remove the prefix from artifacts, such as jar: or pom:
              notation.gsub(/^.+?:/, '')
            end
          end

        # List all dependencies
        else
          lockfile_dependencies(lockfile, groups, with_locals) do |group|
            group['dependencies']
          end
        end
      end
    end
  end
end
