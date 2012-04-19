# Require the correct version of popen for the current platform
if RbConfig::CONFIG['host_os'] =~ /mingw|mswin/
  begin
    require 'win32/open3'
  rescue LoadError
    abort "Run `gem install win32-open3` to be able to run specs"
  end
else
  require 'open3'
end


module BundlerHelper
  
  # Taken from Bundler spec supprt
  # https://github.com/carlhuda/bundler/tree/master/spec/support
  
  attr_reader :out, :err, :exitstatus
  
  def gemfile(*args)
    path = bundled_app("Gemfile")
    path = args.shift if Pathname === args.first
    str  = args.shift || ""
    path.dirname.mkpath
    File.open(path.to_s, 'w') do |f|
      f.puts str
    end
  end

  def lockfile(*args)
    path = bundled_app("Gemfile.lock")
    path = args.shift if Pathname === args.first
    str  = args.shift || ""

    # Trim the leading spaces
    spaces = str[/\A\s+/, 0] || ""
    str.gsub!(/^#{spaces}/, '')

    File.open(path.to_s, 'w') do |f|
      f.puts str
    end
  end
  
  def install_gemfile(*args)
    gemfile(*args)
    opts = args.last.is_a?(Hash) ? args.last : {}
    bundle :install, opts
  end
  
  def bundle(cmd, options = {})
      expect_err  = options.delete(:expect_err)
      exitstatus = options.delete(:exitstatus)
      options["no-color"] = true unless options.key?("no-color") || %w(exec conf).include?(cmd.to_s[0..3])

      #bundle_bin = File.expand_path('../../../bin/bundle', __FILE__)
      bundle_bin = `which bundle`.strip
        
      requires = options.delete(:requires) || []
      requires << File.expand_path('../fakeweb/'+options.delete(:fakeweb)+'.rb', __FILE__) if options.key?(:fakeweb)
      requires << File.expand_path('../artifice/'+options.delete(:artifice)+'.rb', __FILE__) if options.key?(:artifice)
      requires_str = requires.map{|r| "-r#{r}"}.join(" ")

      env = (options.delete(:env) || {}).map{|k,v| "#{k}='#{v}' "}.join
      args = options.map do |k,v|
        v == true ? " --#{k}" : " --#{k} #{v}" if v
      end.join

      cmd = "#{env}#{Gem.ruby} -I#{lib} #{requires_str} #{bundle_bin} #{cmd}#{args}"

      #puts cmd
      
      if exitstatus
        sys_status(cmd)
      else
        sys_exec(cmd, expect_err){|i| yield i if block_given? }
      end
    end
  
  def root
    @root ||= Pathname.new(File.expand_path("../../..", __FILE__))
  end
  
  def bundled_app(*path)
    root = tmp.join("bundled_app")
    FileUtils.mkdir_p(root)
    root.join(*path)
  end
  
  def tmp(*path)
    root.join("tmp", *path)
  end
  
  def in_app_root(&blk)
      Dir.chdir(bundled_app, &blk)
  end
  
  def lib
      File.expand_path('../../../lib', __FILE__)
  end
  
  def sys_exec(cmd, expect_err = false)
    Open3.popen3(cmd.to_s) do |stdin, stdout, stderr|
      @in_p, @out_p, @err_p = stdin, stdout, stderr

      yield @in_p if block_given?
      @in_p.close

      @out = @out_p.read_available_bytes.strip
      @err = @err_p.read_available_bytes.strip
    end

    #puts @out
    puts @err unless expect_err || @err.empty? || !$show_err
    @out
  end
  
  def ruby(ruby, options = {})
    expect_err = options.delete(:expect_err)
    env = (options.delete(:env) || {}).map{|k,v| "#{k}='#{v}' "}.join
    ruby.gsub!(/["`\$]/) {|m| "\\#{m}" }
    lib_option = options[:no_lib] ? "" : " -I#{lib}"
     
    #puts %{#{env}#{Gem.ruby}#{lib_option} -e "#{ruby}"} 
      
    sys_exec(%{#{env}#{Gem.ruby}#{lib_option} -e "#{ruby}"}, expect_err)
  end
  
  RSpec::Matchers.define :have_dep do |*args|
    dep = Bundler::Dependency.new(*args)

    match do |actual|
      actual.length == 1 && actual.all? { |d| d == dep }
    end
  end
end

class IO
  def read_available_bytes(chunk_size = 16384, select_timeout = 0.02)
    buffer = []

    return "" if closed? || eof?
    # IO.select cannot be used here due to the fact that it
    # just does not work on windows
    while true
      begin
        IO.select([self], nil, nil, select_timeout)
        break if eof? # stop raising :-(
        buffer << self.readpartial(chunk_size)
      rescue(EOFError)
        break
      end
    end

    return buffer.join
  end
end