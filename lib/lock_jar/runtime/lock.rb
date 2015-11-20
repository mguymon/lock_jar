require 'delegate'

module LockJar
  #
  class Runtime
    #
    class Lock < SimpleDelegator
      attr_accessor :jarfile, :lockfile, :opts

      def initialize(runtime)
        super(runtime)

        @lockfile = LockJar::Domain::Lockfile.new
      end

      def lock(jarfile_or_dsl, opts = {}, &blk)
        @opts = { download: true }.merge(opts)

        create_dsl!(jarfile_or_dsl, &blk)

        apply_repositories!

        apply_maps!

        apply_excludes!

        apply_merged!

        artifacts = jarfile.artifacts.values.flatten
        apply_artifacts!(artifacts) unless artifacts.empty?

        lockfile.write(@opts[:lockfile] || 'Jarfile.lock')

        lockfile
      end

      private

      def create_dsl!(jarfile_or_dsl, &blk)
        if jarfile_or_dsl
          if jarfile_or_dsl.is_a? LockJar::Domain::Dsl
            @jarfile = jarfile_or_dsl
          else
            @jarfile = LockJar::Domain::JarfileDsl.create(jarfile_or_dsl)
          end
        end

        return @jarfile if blk.nil?

        if @jarfile
          @jarfile = LockJar::Domain::DslMerger.new(
            jarfile, LockJar::Domain::Dsl.create(&blk)).merge
        else
          @jarfile = LockJar::Domain::Dsl.create(&blk)
        end
      end

      # rubocop:disable Metrics/AbcSize
      def apply_artifacts!(artifacts)
        # Build the dependencies_graph hash in the resolver
        resolver(opts).resolve(
          artifacts.select(&:resolvable?).map(&:to_dep), opts[:download] == true
        )

        jarfile.artifacts.each do |group_name, group_artifacts|
          group = { 'locals' => [], 'dependencies' => [], 'artifacts' => [] }

          group_artifacts.each do |artifact|
            artifact_data = {}

            add_artifact!(group, artifact_data, artifact)

            next unless artifact_data['transitive']

            # flatten the graph of nested hashes
            group['dependencies'] += dependency_merge(artifact_data['transitive'])
            # xxX: set required_by ?
            group['artifacts'] << { artifact.to_urn => artifact_data }
          end

          lockfile.excludes.each do |exclude|
            group['dependencies'].delete_if { |dep| dep =~ /#{exclude}/ }
          end if lockfile.excludes

          group['dependencies'] = group['dependencies'].sort.uniq

          group.delete 'locals' if group['locals'].empty?

          lockfile.groups[group_name] = group
        end
      end
      # rubocop:enable Metrics/AbcSize

      def apply_excludes!
        lockfile.excludes = jarfile.excludes if jarfile.excludes.size > 0
      end

      def apply_maps!
        lockfile.maps = jarfile.maps if jarfile.maps.size > 0
      end

      def apply_merged!
        lockfile.merged = jarfile.merged unless jarfile.merged.empty?
      end

      def apply_repositories!
        lockfile.local_repository = opts[:local_repo] ||= jarfile.local_repository

        if jarfile.clear_repositories
          resolver(opts).clear_remote_repositories
        else
          repos = resolver(opts).remote_repositories
          lockfile.remote_repositories += repos.to_a if repos
        end

        # Add remote repos to the resolver and the lockfile
        jarfile.remote_repositories.each do |repo|
          resolver(opts).add_remote_repository(repo)
          lockfile.remote_repositories << repo
        end
      end

      def add_artifact!(group, artifact_data, artifact)
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
      end

      def dependency_merge(graph)
        deps = graph.keys
        graph.values.flat_map { |next_step| deps += dependency_merge(next_step) }
      end
    end
  end
end
