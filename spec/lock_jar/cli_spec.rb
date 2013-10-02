require 'spec_helper'

describe "lockjar" do

  include Spec::Helpers

  before(:all) do
    install_jarfile <<-J
jar "com.google.guava:guava:14.0.1"
J
  end

  after(:all) do
    FileUtils.rm("Jarfile")
    FileUtils.rm("Jarfile.lock") rescue nil
  end

  it "should show everything" do
    lockjar ''
    expect(@out).to eq(
'Commands:
  lockjar help [COMMAND]  # Describe available commands or one specific command
  lockjar install         # Install Jars from a Jarfile.lock
  lockjar list            # List Jars from a Jarfile.lock
  lockjar lock            # Lock Jars in a Jarfile.lock
  lockjar maven           # Run tasks on a Maven POM
  lockjar version         # LockJar version')
  end

  context "version" do
    before do
      @version = File.read(File.join(File.dirname(__FILE__), "..", "..", "VERSION"))
    end

    it "should return correct version" do
      lockjar "version"
      expect(@out).to eq(@version)
    end
  end

  context "lock" do
    it "should create lock file with default path" do
      FileUtils.rm("Jarfile.lock") rescue nil
      lockjar "lock"
      expect(@out).to match(/^Locking Jarfile to Jarfile.lock.*/)
      expect(File.exists?("Jarfile.lock")).to be_true
    end

    it "should create lock file with specific path" do
      jarfile_path = File.join("spec", "support", "Jarfile")
      jarfile_lock_path = File.join("spec", "support", "Jarfile.lock")
      FileUtils.rm(jarfile_lock_path) rescue nil

      lockjar "lock -j #{jarfile_path} -l #{jarfile_lock_path}"
      expect(@out).to eq("Locking #{jarfile_path} to #{jarfile_lock_path}")
      expect(File.exists?(jarfile_lock_path)).to be_true
    end
  end

  context "list" do

    it "should list with default path" do
      FileUtils.rm("Jarfile.lock") rescue nil
      lockjar "lock"

expect_output =<<-EOM.strip
Listing Jars from Jarfile.lock for ["default"]
["com.google.guava:guava:jar:14.0.1"]
EOM

      lockjar "list"
      expect(@out).to eq(expect_output)
    end

    it "should list with specific path" do
      jarfile_path = File.join("spec", "support", "Jarfile")
      jarfile_lock_path = File.join("spec", "support", "Jarfile.lock")
      FileUtils.rm(jarfile_lock_path) rescue nil
      lockjar "lock -j #{jarfile_path} -l #{jarfile_lock_path}"

expect_expr = Regexp.new(<<-'EOM'.strip)
Listing Jars from .*Jarfile.lock for \["default"\]
\["com.google.guava:guava:jar:14.0.1"\]
EOM

      lockjar "list -l #{jarfile_lock_path}"
      expect(@out).to match(expect_expr)
    end
  end

  context "install" do
    it "should install jar archives with default path" do
      FileUtils.rm("Jarfile.lock") rescue nil
      lockjar "lock"

      lockjar "install"
      expect(@out).to eq("Installing Jars from Jarfile.lock for [\"default\"]")
      LockJar.load
      expect(Java::ComGoogleCommonCollect::Multimap).to be_kind_of(Module) if is_jruby?
    end

    it "should install jar archives with specific path" do
      jarfile_path = File.join("spec", "support", "Jarfile")
      jarfile_lock_path = File.join("spec", "support", "Jarfile.lock")
      FileUtils.rm(jarfile_lock_path) rescue nil
      lockjar "lock -j #{jarfile_path} -l #{jarfile_lock_path}"

      lockjar "install -l #{jarfile_lock_path}"
      expect(@out).to eq("Installing Jars from #{jarfile_lock_path} for [\"default\"]")
      LockJar.load(jarfile_lock_path)
      expect(Java::ComGoogleCommonCollect::Multimap).to be_kind_of(Module) if is_jruby?
    end
  end

end
