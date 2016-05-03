require 'spec_helper'

describe LockJar::Config do
  describe '.load_config_file' do
    let(:test_config_file) { File.join('spec', 'fixtures', 'lock_jar_config.yml') }
    let(:temp_config_file) { File.join(TEMP_DIR, described_class::DEFAULT_FILENAME) }
    let(:config) { described_class.load_config_file }
    let(:expected_repo_config) do
      {
        'https://some.fancy.doman/maven' => {
          'username' => 'user1',
          'password' => 'the_pass'
        }
      }
    end

    before do
      FileUtils.cp(test_config_file, temp_config_file)
    end

    context 'using current dir config' do
      before do
        allow(Dir).to receive(:pwd).and_return(TEMP_DIR)
      end

      it 'should have a repository config' do
        expect(config.repositories).to eq(expected_repo_config)
      end
    end

    context 'using home dir config' do

      before do
        allow(Dir).to receive(:home).and_return(TEMP_DIR)
      end

      it 'should have a repository config' do
        expect(config.repositories).to eq(expected_repo_config)
      end
    end

    context 'using ENV path to config' do
      before do
        ENV[described_class::CONFIG_ENV] = temp_config_file
      end

      it 'should have a repository config' do
        expect(config.repositories).to eq(expected_repo_config)
      end
    end
  end
end
