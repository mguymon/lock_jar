require 'yaml'

module LockJar
  # Handle authentication for
  class Config
    CONFIG_ENV = 'LOCKJAR_CONFIG'.freeze
    DEFAULT_FILENAME = '.lockjar'.freeze

    attr_reader :repositories

    class << self
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
    #       'ssh_key' => ''
    #     }
    #   }
    # }
    def initialize(config)
      @repositories = config['repositories'] || {}
    end
  end
end
