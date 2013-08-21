require 'open3'

module Spec
  module Helpers
    def lockjar(cmd, options = {})
      lockjar_bin = File.expand_path('../../../bin/lockjar', __FILE__)
      cmd = "#{lockjar_bin} #{cmd}"

      sys_exec(cmd)
    end

    def sys_exec(cmd, expect_err = false)
      Open3.popen3(cmd.to_s) do |stdin, stdout, stderr|
        @in_p, @out_p, @err_p = stdin, stdout, stderr

        yield @in_p if block_given?
        @in_p.close

        @out = @out_p.read.strip
        @err = @err_p.read.strip
      end

      puts @err unless expect_err || @err.empty? || !$show_err
      @out
    end

    def locked_app(*path)
      root = tmp.join("bundled_app")
      FileUtils.mkdir_p(root)
      root.join(*path)
    end
  end
end
