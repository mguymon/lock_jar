module LockJar
  #
  class Runtime
    #
    module Lock
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def lock(jarfile_or_dsl, opts = {}, &blk)
        opts = { download: true }.merge(opts)

        jarfile = nil

        if jarfile_or_dsl
          if jarfile_or_dsl.is_a? LockJar::Domain::Dsl
            jarfile = jarfile_or_dsl
          else
            jarfile = LockJar::Domain::JarfileDsl.create(jarfile_or_dsl)
          end
        end

        unless blk.nil?
          dsl = LockJar::Domain::Dsl.create(&blk)
          if jarfile.nil?
            jarfile = dsl
          else
            jarfile = LockJar::Domain::DslMerger(jarfile, dsl).merge
          end
        end

        # If not set in opts, and is set in  dsl
        if opts[:local_repo].nil? && jarfile.local_repository
          opts[:local_repo] = jarfile.local_repository
        end

        lockfile = LockJar::Domain::Lockfile.new

        if jarfile.clear_repositories
          resolver(opts).clear_remote_repositories
        else
          repos = resolver(opts).remote_repositories
          lockfile.remote_repositories += repos.to_a if repos
        end

        jarfile.remote_repositories.each do |repo|
          resolver(opts).add_remote_repository(repo)
          lockfile.remote_repositories << repo
        end

        lockfile.local_repository = jarfile.local_repository unless jarfile.local_repository.nil?

        lockfile.maps = jarfile.maps if jarfile.maps.size > 0

        lockfile.excludes = jarfile.excludes if jarfile.excludes.size > 0

        artifacts = []
        jarfile.artifacts.each do |_, group_artifacts|
          artifacts += group_artifacts
        end

        lockfile.merged = jarfile.merged unless jarfile.merged.empty?

        unless artifacts.empty?
          resolver(opts).resolve(
            artifacts.select(&:resolvable?).map(&:to_dep),
            opts[:download] == true
          )

          jarfile.artifacts.each do |group_name, group_artifacts|
            group = { 'locals' => [], 'dependencies' => [], 'artifacts' => [] }

            group_artifacts.each do |artifact|
              artifact_data = {}

              if artifact.is_a? LockJar::Domain::Jar
                group['dependencies'] << artifact.notation
                g = resolver(opts).dependencies_graph[artifact.notation]
                artifact_data['transitive'] = g.to_hash if g

              elsif artifact.is_a? LockJar::Domain::Pom
                artifact_data['scopes'] = artifact.scopes

                # iterate each dependency in Pom to map transitive dependencies
                transitive = {}
                artifact.notations.each do |notation|
                  transitive.merge!(notation => resolver(opts).dependencies_graph[notation])
                end
                artifact_data['transitive'] = transitive

              elsif artifact.is_a? LockJar::Domain::Local
                group['locals'] << artifact.path
              else
                fail("Unsupported artifact: #{artifact.inspect}")
              end

              # flatten the graph of nested hashes
              dep_merge = lambda do |graph|
                deps = graph.keys
                graph.values.each do |next_step|
                  deps += dep_merge.call(next_step)
                end
                deps
              end

              next unless artifact_data['transitive']

              group['dependencies'] += dep_merge.call(artifact_data['transitive'])
              # xxX: set required_by ?
              group['artifacts'] << { artifact.to_urn => artifact_data }
            end

            lockfile.excludes.each do |exclude|
              group['dependencies'].delete_if { |dep| dep =~ /#{exclude}/ }
            end if lockfile.excludes

            group['dependencies'].sort!
            group.delete 'locals' if group['locals'].empty?

            lockfile.groups[group_name] = group
          end
        end

        lockfile.write(opts[:lockfile] || 'Jarfile.lock')

        lockfile
      end
      # rubocop:enable Metrics/CyclomaticComplexity, , Metrics/PerceivedComplexity
    end
  end
end
