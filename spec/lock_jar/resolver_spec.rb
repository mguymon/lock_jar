require 'spec_helper'
require 'lock_jar/resolver'
require 'fileutils'
require 'naether'

describe LockJar::Resolver do
  before(:each) do
    FileUtils.mkdir_p("#{TEMP_DIR}/test-repo")
    @resolver = LockJar::Resolver.new(local_repo: "#{TEMP_DIR}/test-repo")
  end

  it 'should bootstrap naether' do
    deps = Naether::Bootstrap.check_local_repo_for_deps("#{TEMP_DIR}/test-repo")
    deps[:missing].should eql([])
    deps[:exists].each do |dep|
      expect(dep.values[0]).to match(/#{TEMP_DIR}#{File::SEPARATOR}test-repo#{File::SEPARATOR}.+/)
    end
  end

  it 'should return local paths for notations' do
    expect(@resolver.to_local_paths(['org.testng:testng:jar:6.9.10'])).to(
      eql([File.expand_path("#{TEMP_DIR}/test-repo/org/testng/testng/6.9.10/testng-6.9.10.jar")])
    )
  end
end
