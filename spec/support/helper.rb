require 'open3'
require 'pathname'

module Spec
  module Helpers
    def remove_file(path)
      FileUtils.rm(path) if File.exist? path
    end

    def lockjar(cmd, _options = {})
      lockjar_bin = File.expand_path('../../../bin/lockjar', __FILE__)
      cmd = "ruby -I#{lib} #{lockjar_bin} #{cmd}"

      sys_exec(cmd)
    end

    def lib
      File.expand_path('../../../lib', __FILE__)
    end

    # rubocop:disable Style/GlobalVars
    def sys_exec(cmd, expect_err = false)
      Open3.popen3(cmd.to_s) do |stdin, stdout, stderr|
        @in_p = stdin
        @out_p = stdout
        @err_p = stderr

        yield @in_p if block_given?
        @in_p.close

        @out = @out_p.read.strip
        @err = @err_p.read.strip
      end

      puts @err unless expect_err || @err.empty? || !$show_err
      @out
    end
    # rubocop:enable Style/GlobalVars

    def install_jarfile(*args)
      root_path ||= Pathname.new(File.expand_path('../../..', __FILE__))
      jarfile_path = root_path.join('Jarfile')
      File.open(jarfile_path.to_s, 'w') do |f|
        f.puts args.last
      end
    end

    def is_jruby?
      defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby')
    end
  end
end
