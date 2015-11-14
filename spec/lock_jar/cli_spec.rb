require 'spec_helper'

describe 'lockjar' do
  include Spec::Helpers

  before do
    install_jarfile <<-J
jar 'com.google.guava:guava:14.0.1'
J
  end

  after do
    remove_file('Jarfile')
    remove_file('Jarfile.lock')
  end

  context 'version' do
    it 'should return correct version' do
      lockjar 'version'
      expect(@out).to eq(LockJar::VERSION)
    end
  end

  context 'lock' do
    it 'should create lock file with default path' do
      lockjar 'lock'
      expect(@out).to match(/^Locking Jarfile to Jarfile.lock.*/)
      expect(File).to exist('Jarfile.lock')
    end

    it 'should create lock file with specific path' do
      jarfile_path = File.join('spec', 'support', 'Jarfile')
      jarfile_lock_path = File.join('spec', 'support', 'Jarfile.lock')
      remove_file(jarfile_lock_path)

      lockjar "lock -j #{jarfile_path} -l #{jarfile_lock_path}"
      expect(@out).to eq("Locking #{jarfile_path} to #{jarfile_lock_path}")
      expect(File).to exist(jarfile_lock_path)
    end
  end

  context 'list' do
    it 'should list with default path' do
      lockjar 'lock'

      expect_output = %(
Listing Jars from Jarfile.lock for ["default"]
["com.google.guava:guava:jar:14.0.1"]
      ).strip

      lockjar 'list'
      expect(@out).to eq(expect_output)
    end

    it 'should list with specific path' do
      jarfile_path = File.join('spec', 'support', 'Jarfile')
      jarfile_lock_path = File.join('spec', 'support', 'Jarfile.lock')
      remove_file(jarfile_lock_path)
      lockjar "lock -j #{jarfile_path} -l #{jarfile_lock_path}"

      expect_expr = Regexp.new(<<-'EOM'.strip)
Listing Jars from .*Jarfile.lock for \["default"\]
\["com.google.guava:guava:jar:14.0.1"\]
EOM

      lockjar "list -l #{jarfile_lock_path}"
      expect(@out).to match(expect_expr)
    end
  end

  context 'install' do
    it 'should install jar archives with default path' do
      lockjar 'lock'

      lockjar 'install'
      expect(@out).to eq(%(Installing Jars from Jarfile.lock for ["default"]))
      LockJar.load
      expect(Java::ComGoogleCommonCollect::Multimap).to be_kind_of(Module) if is_jruby?
    end

    it 'should install jar archives with specific path' do
      jarfile_path = File.join('spec', 'support', 'Jarfile')
      jarfile_lock_path = File.join('spec', 'support', 'Jarfile.lock')
      remove_file(jarfile_lock_path)
      lockjar "lock -j #{jarfile_path} -l #{jarfile_lock_path}"

      lockjar "install -l #{jarfile_lock_path}"
      expect(@out).to eq(%(Installing Jars from #{jarfile_lock_path} for ["default"]))
      LockJar.load(jarfile_lock_path)
      expect(Java::ComGoogleCommonCollect::Multimap).to be_kind_of(Module) if is_jruby?
    end
  end
end
