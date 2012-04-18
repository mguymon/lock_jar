require 'spec_helper'
require 'rubygems'
require 'bundler'
require 'lib/lock_jar/bundler'

describe Bundler do
    before(:each) do
      gemfile <<-G
        source "file://#{tmp('bundler')}"
        gem "rack"
        group :test do
          jar 'junit:junit:jar:4.10'
        end
        
        pom 'spec/pom.xml', :group => :development
        
      G
      in_app_root
    end
  
  it "provides a list of the env dependencies" do
    Bundler.load.dependencies.should have_dep("rack", ">= 0")
  end
    
  it "provides a list of the jar and pom dependencies" do
    Bundler.load.jars.should eql( [{"junit:junit:jar:4.10"=>[:test]}] )
    Bundler.load.poms.should eql( [{'spec/pom.xml'=>[:compile]}] )
  end
  
  # Taken from Bunlder spec supprt
  # https://github.com/carlhuda/bundler/tree/master/spec/support
  
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
    
    RSpec::Matchers.define :have_dep do |*args|
      dep = Bundler::Dependency.new(*args)

      match do |actual|
        actual.length == 1 && actual.all? { |d| d == dep }
      end
    end
end