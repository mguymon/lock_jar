# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements. See the NOTICE file distributed with this
# work for additional information regarding copyright ownership. The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

require 'lock_jar/runtime'
require 'naether/maven'
require 'digest/md5'
require 'zip'
require 'yaml'

module LockJar
  
  # Helper for providing Maven specific operations
  #
  # @author Michael Guymon
  # 
  class Maven
    
    class << self
      
      #
      # Get the version of a POM
      #
      # @param [String] pom_path path to the pom
      #
      # @return [String] version of POM
      #
      def pom_version( pom_path )
        maven = Naether::Maven.create_from_pom( pom_path )
        maven.version()
      end
      
      #
      # Get dependencies of a Pom
      #
      # @param [String] pom_path path to the pom
      # @param [Array] scopes
      #
      # @return [String] version of POM
      #
      def dependencies( pom_path, scopes = ['compile', 'runtime'] )
        maven = Naether::Maven.create_from_pom( pom_path )
        maven.dependencies(scopes)
      end
      
      #
      # Write a POM from list of notations
      #
      # @param [String] pom notation
      # @param [String] file_path path of new pom
      # @param [Hash] opts
      # @option opts [Boolean] :include_resolved to add dependencies of resolve dependencies from Jarfile.lock. Default is true.
      # @option opts [Array] :dependencies Array of of mixed dependencies:
      #  * [String] Artifact notation, such as groupId:artifactId:version, e.g. 'junit:junit:4.7' 
      #  * [Hash] of a single artifaction notation => scope - { 'junit:junit:4.7' => 'test' }
      #
      def write_pom( notation, file_path, opts = {} )
        opts = {:include_resolved => true}.merge( opts )
        
        maven = Naether::Maven.create_from_notataion( notation )
        
        if opts[:include_resolved]
          # Passes in nil to the resolver to get the cache
          maven.load_naether( Runtime.instance.resolver.naether )
        end
        
        if opts[:dependencies]
          opts[:dependencies].each do |dep|
            if dep.is_a? Array
              maven.add_dependency(dep[0], dep[1])
            else
              maven.add_dependency(dep)
            end
          end
        end
        maven.write_pom( file_path )
      end
      
      #
      # Deploy an artifact to a Maven repository
      #
      # @param [String] notation of artifact
      # @param [String] file_path path to the Jar
      # @param [String] url Maven repository deploying to
      # @param [Hash] deploy_opts options for deploying 
      # @param [Hash] lockjar_opts options for initializing LockJar
      #
      def deploy_artifact( notation, file_path, url, deploy_opts = {}, lockjar_opts = {} )
        Runtime.instance.resolver(lockjar_opts).naether.deploy_artifact( notation, file_path, url, deploy_opts )
      end
      
      #
      # Install an artifact to a local repository
      #
      # @param [String] notation of artifact
      # @param [String] pom_path path to the pom
      # @param [String] jar_path path to the jar
      # @param [Hash] opts options
      #
      def install( notation, pom_path, jar_path, opts = {} )
        Runtime.instance.resolver(opts).naether.install( notation, pom_path, jar_path )
      end

      #
      # Invoke a Maven goal, such as compile or package
      #
      # @param [String] pom_path path
      # @param [Array] goals Array of goals to run
      # @param [Hash] opts
      def invoke( pom_path, goals, opts={} )
        maven = Naether::Maven.create_from_pom( pom_path )
        maven.invoke(goals, opts)
      end

      # Build an Uberjar for a Maven pom
      def uberjar(pom, opts = {})
        config = {
            :package => true,
            :force => false,
            :assembly_dir => File.join('target', 'assembly')
        }.merge(opts)

        assembly_dir = config[:assembly_dir]

        maven = Naether::Maven.create_from_pom( pom )
        if config[:package]
          maven.invoke('package', config)
        end

        resolved_deps = LockJar.list( config.merge( :resolve => true) ) do
          pom pom_path
        end

        deps_md5 = Digest::MD5.hexdigest( resolved_deps.sort.join(' ') )
        file_md5 = nil

        if File.exists?( File.join( assembly_dir, 'dependencies.md5' ) )
          file_md5 = IO.read( File.join( assembly_dir, 'dependencies.md5' ) ).strip
        end

        # If the deps did not change, do not explode everything again . . for no reason
        if !opts[:force] || ( file_md5 && file_md5 == deps_md5 )
          puts "Jars did not change"

        # Something is different, crack em all open
        else

          # Remove the old assembly
          if File.exists?( assembly_dir )
            FileUtils.rm_rf(assembly_dir )
          end

          # A fresh dir
          FileUtils.mkdir( assembly_dir )

          # This should use the cached results from the previous call
          artifacts = LockJar.list( config.merge( :resolve => true, :local_paths => true ) ) do
            pom pom_path
          end

          puts "Exploding #{artifacts.size} jars into #{assembly_dir}"

          artifacts.each do |artifact|

            unzip(artifact, assembly_dir)

            # A hack for the LICENSE file name vs license directory confusion.
            FileUtils.rm_rf("#{_(assembly_dir)}/license")

            # TODO: support files that must be appended, such as the Spring whatcamacallems
          end

          # TODO: unzip local jars

          # Remove signed jar files
          FileUtils.rm_rf(Dir.glob("#{_(assembly_dir)}/META-INF/*.SF"))
          FileUtils.rm_rf(Dir.glob("#{_(assembly_dir)}/META-INF/*.DSA"))
          FileUtils.rm_rf(Dir.glob("#{_(assembly_dir)}/META-INF/*.RSA"))

          # Write the dependencies md5
          File.open( File.join(assembly_dir, 'dependencies.md5'), "w") { |f| f.write( deps_md5 ) }

        end

        # TODO: Unzip project zip
        # TODO: Add project zip to dependencies

        # Write dependencies yaml
        File.write(File.join(assembly_dir, 'dependencies.yml'), {'dependencies' => resolved_deps}.to_yaml)

        # Remove the MANIFEST.MF from the exploded jars
        FileUtils.rm( File.join(assembly_dir, 'META-INF', 'MANIFEST.MF') )

        # create manifest file
        File.open( File.join(assembly_dir, 'META-INF', 'MANIFEST.MF'), 'w') do |f|
          f.write("Implementation-Title: Title\n")
          f.write("Implementation-Version: Version\n")
          f.write("Manifest-Version: 1.0\n")
          f.write("Main-Class: com/main/main/Main\n")
          f.write("Created-By: LockJar\n")
        end

        # get the present dir
        present_dir = Dir.pwd

        # change to the assembly dir
        Dir.chdir assembly_dir

        # TODO: get name of uberjar to create
        puts "Creating blah"
        `jar -cfm target/blah.jar assembly_dir/META-INF/MANIFEST.MF .`

        # return to original dir
        Dir.chdir present_dir


      end

      private
      def unzip(zip_file, destination)
        Zip::File.open(zip_file) do |zipfile|
          zipfile.each do |file|

            # A directory entry
            if file.name[-1] == '/'
              dir = File.join( destination, file.name )
              FileUtils::mkdir_p(dir)

            # Otherwise a file
            else
              dir = File.join( destination, File.dirname(file.name))
              FileUtils::mkdir_p(dir)

              # Create zip, overwrite files
              file.extract(File.join( destination, file.name)) { true }
            end
          end
        end
      end
    end
  end
end