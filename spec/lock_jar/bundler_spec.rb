require 'spec_helper'
require 'rubygems'
require 'bundler'
require 'lib/lock_jar/bundler'
require 'helper/bundler_helper'

describe Bundler do
    include BundlerHelper
    
    before(:each) do
      gemfile <<-G
        require 'lock_jar/bundler'
        source "file://#{tmp('bundler')}"
        gem "naether"
        
        lock_jar do
          scope :test do
            jar 'junit:junit:jar:4.10'
          end
          
          pom "#{File.join(root, 'spec', 'pom.xml')}", :scope => :development
        end
      G
      in_app_root
    end
    
    after(:each) do
      Dir.chdir(root)
    end
  
  it "provides a list of the env dependencies" do
    Bundler.load.dependencies.should have_dep("naether", ">= 0")
  end
    
  it "provides a list of the jar and pom dependencies" do
    Bundler.load.lock_jar.notations.should eql( {"compile"=>["/home/zinger/devel/projects/swx/lock_jar/spec/pom.xml"], "runtime"=>[], "test"=>["junit:junit:jar:4.10"]} )
  end
  
  it "should create Jarfile.lock with bundle install" do
    File.delete( bundled_app("Jarfile.lock") ) if File.exists? bundled_app("Jarfile.lock")
    install_gemfile <<-G
      require 'lock_jar/bundler'
      source "file://#{tmp('bundler')}"
      gem "naether"
      
      lock_jar do
        scope :test do
          jar 'junit:junit:jar:4.10'
        end
        
        pom "#{File.join(root, 'spec', 'pom.xml')}", :scope => :development
      end
      
    G
    
    File.exists?(  bundled_app("Jarfile.lock") ).should be_true
    
    IO.read( File.join(root,'spec', 'BundlerJarfile.lock') ).should eql( IO.read( bundled_app("Jarfile.lock") ) )
  end
  
  it "should create Jarfile.lock with bundle update" do
    File.delete( bundled_app("Jarfile.lock") ) if File.exists? bundled_app("Jarfile.lock")
    bundle "update"
    File.exists?(  bundled_app("Jarfile.lock") ).should be_true
    
    IO.read( File.join(root,'spec', 'BundlerJarfile.lock') ).should eql( IO.read( bundled_app("Jarfile.lock") ) )
  end
  
  it "should load Jarfile.lock with Bundle.setup" do
    ruby <<-RUBY
      require 'rubygems'
      require 'bundler'
      require 'lock_jar/bundler'
      Bundler.setup

      puts com.slackworks.modelcitizen.ModelFactory.to_s
    RUBY
    err.should eq("")
    out.should match("Java::ComSlackworksModelcitizen::ModelFactory")
  end
  
end