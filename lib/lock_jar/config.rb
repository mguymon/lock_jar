require 'yaml'

module LockJar
  # Global configuration for LockJar
  class Config
    CONFIG_ENV = 'LOCKJAR_CONFIG'.freeze
    DEFAULT_FILENAME = '.lockjar'.freeze

    attr_reader :repositories

    class << self
      # Load .lockjar YAML config file from ENV['LOCKJAR_CONFIG'], current_dir, or
      # home dir.
      def load_config_file
        local_config_paths =
          [Dir.pwd, Dir.home]
          .map { |path| File.join(path, DEFAULT_FILENAME) }

        config_path =
          ([ENV[CONFIG_ENV]] + local_config_paths)
          .compact
          .find { |path| File.exist? path }

        new(YAML.load(IO.read(config_path))) if config_path
      end
    end

    #
    # {
    #   'repositories' => {
    #     ':url' => {
    #       'username' => ''
    #       'password' => ''
    #     }
    #   }
    # }
    def initialize(config)
      @repositories = config['repositories'] || {}
    end
  end
end
