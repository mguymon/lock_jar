require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
  
require 'rubygems'
require 'bundler'
require 'lib/lock_jar/bundler'
require 'helper/bundler_helper'
require 'fileutils'

describe Bundler do
    include BundlerHelper
    
    before(:all) do
      FileUtils.rm_rf( bundled_app ) if File.exists? bundled_app
    end
    
    before(:each) do
      gemfile <<-G
        require 'lib/lock_jar/bundler'
        gem "naether"
        
        lock_jar do
          scope :test do
            jar 'junit:junit:jar:4.10'
          end
          
          pom "#{File.join(root, 'spec', 'pom.xml')}", :scope => :development
        end
      G
      
      ENV['BUNDLE_GEMFILE'] = bundled_app("Gemfile").to_s
      
      in_app_root
    end
    
    after(:all) do
      puts "Changing pwd back to #{root}"
      Dir.chdir(root)
    end
  
  it "provides a list of the env dependencies" do
    dep = Bundler.load.dependencies.first
    dep.name.should eql("naether")
    (dep.requirement >= ">= 0").should be_true
  end
    
  it "provides a list of the jar and pom dependencies" do
    # XXX: In JRuby - works in autotest, fails directly from rspec. *sigh*
    Bundler.load.lock_jar.notations.should eql( {"compile"=>[File.expand_path(File.join(File.dirname(__FILE__), "../../spec/pom.xml"))], "runtime"=>[], "test"=>["junit:junit:jar:4.10"]} )
  end
  
  it "should create Jarfile.lock with bundle install" do
    File.delete( bundled_app("Jarfile.lock") ) if File.exists? bundled_app("Jarfile.lock")
    install_gemfile <<-G
      require 'lock_jar/bundler'
      gem "naether"
      
      lock_jar do
        scope :test do
          jar 'junit:junit:jar:4.10'
        end
        
        pom "#{File.join(root, 'spec', 'pom.xml')}", :scope => :development
      end
      
    G
    File.exists?( bundled_app("Jarfile.lock") ).should be_true
    
    LockJar.read( File.join(root,'spec', 'BundlerJarfile.lock') ).should eql( LockJar.read( bundled_app("Jarfile.lock") ) )
  end
  
  it "should create Jarfile.lock with bundle update" do
    File.delete( bundled_app("Jarfile.lock") ) if File.exists? bundled_app("Jarfile.lock")
    bundle "update"
    File.exists?(  bundled_app("Jarfile.lock") ).should be_true
    
    LockJar.read( File.join(root,'spec', 'BundlerJarfile.lock') ).should eql( LockJar.read( bundled_app("Jarfile.lock") ) )
  end
  
  it "should load Jarfile.lock with Bundle.setup" do
    LockJar.list( :resolve => true, :local_repo => tmp('test-repo') ) # ensure jars are already downloaded
    
    ruby <<-RUBY
      require 'rubygems'
      require 'bundler'
      require 'lib/lock_jar/bundler'
      require 'naether/java'
      
      LockJar.config( :local_repo => '#{tmp('test-repo')}' )
      
      Bundler.setup

      puts Naether::Java.create('com.slackworks.modelcitizen.ModelFactory').getClass().toString()
    RUBY
    #err.should eq("") # 1.9.3 has a IConv error that outputs to std err
    out.should match("class com.slackworks.modelcitizen.ModelFactory")
  end
  
end