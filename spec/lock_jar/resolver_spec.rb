require 'spec_helper'
require 'lock_jar/resolver'
require 'fileutils'
require 'naether'

describe LockJar::Resolver do
  subject { described_class.new(config, local_repo: "#{TEMP_DIR}/test-repo") }

  before do
    FileUtils.mkdir_p("#{TEMP_DIR}/test-repo")
  end

  let(:config) do
    LockJar::Config.new(
      'repositories' => {
        'https://test/repo' => {
          'username' => 'user1',
          'password' => 'pass1'
        }
      }
    )
  end

  it 'should bootstrap naether' do
    subject

    deps = Naether::Bootstrap.check_local_repo_for_deps("#{TEMP_DIR}/test-repo")
    deps[:missing].should eql([])
    deps[:exists].each do |dep|
      expect(dep.values[0]).to match(/#{TEMP_DIR}#{File::SEPARATOR}test-repo#{File::SEPARATOR}.+/)
    end
  end

  describe '#to_local_paths' do
    it 'should return local paths for notations' do
      expect(subject.to_local_paths(['org.testng:testng:jar:6.9.10'])).to(
        eql([File.expand_path("#{TEMP_DIR}/test-repo/org/testng/testng/6.9.10/testng-6.9.10.jar")])
      )
    end
  end

  describe '#add_remote_repository' do
    let(:remote_repos) do
      subject.naether.remote_repositories.map do |repo|
        {
          url: repo.url
        }.tap do |hash|
          if repo.authentication
            hash[:username] = repo.authentication.username
            hash[:password] = repo.authentication.password
          end
        end
      end
    end

    let(:expected_remote_repos) do
      [
        { url: 'http://repo1.maven.org/maven2/' },
        { url: 'https://test/repo', username: 'user1', password: 'pass1' }
      ]
    end

    it 'should use repo config for auth' do
      subject.add_remote_repository('https://test/repo')

      expect(remote_repos).to eq(expected_remote_repos)
    end
  end
end
