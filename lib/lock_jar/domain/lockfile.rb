
require "yaml"
require 'lock_jar/version'

module LockJar
  module Domain
    class Lockfile
      
      attr_accessor :local_repository, :maps, :excludes, :remote_repositories, 
                    :version, :groups, :gems
      attr_reader :force_utf8
      
      
      def self.read( path )
        lockfile = Lockfile.new
        
        lock_data = YAML.load_file( path )
        
        lockfile.version = lock_data['version'] || LockJar::VERSION
        
        lockfile.local_repository = lock_data['local_repository']
        lockfile.maps = lock_data['maps'] || []
        lockfile.excludes = lock_data['excludes'] || []
        lockfile.groups = lock_data['groups'] || lock_data['scopes'] || {}
        lockfile.remote_repositories = lock_data['remote_repositories'] || lock_data['repositories'] || []
        lockfile.gems = lock_data['gems'] || []
        lockfile
      end
      
      def initialize
        @force_utf8 ||= RUBY_VERSION =~ /^1.9/
        @groups = { 'default' => {} }
        @maps = []
        @excludes = []
        @remote_repositories = []
        @gems = []
        
        @version = LockJar::VERSION # default version
      end
      
      def to_hash
        lock_data = { 'version' => @version }
  
        unless local_repository.nil?
          lock_data['local_repository'] = local_repository
          
          if @force_utf8
            lock_data['local_repository'] = lock_data['local_repository'].force_encoding("UTF-8")
          end
        end
                
        if maps.size > 0
          lock_data['maps'] = maps
        end
        
        if excludes.size > 0 
          lock_data['excludes'] = excludes
            
          if @force_utf8
            lock_data['excludes'].map! { |exclude| exclude.force_encoding("UTF-8") }
          end
        end
        
        unless gems.empty?
          lock_data['gems'] = gems
        end
        
        lock_data['groups'] = groups
        
        #if @force_utf8
        #  lock_data['groups'].each do |group, group_notations|
        #    group_notations.map! { |notation| notation.force_encoding("UTF-8") }
        #  end
        #end
        
        if remote_repositories.size > 0
          lock_data['remote_repositories'] = remote_repositories
        end
        
        lock_data
      end
      
      def to_yaml
        to_hash.to_yaml
      end
      
      def write( path )
        File.open( path, "w") do |f|
          f.write( to_yaml )
        end
      end
    end
  end
end