require 'spec_helper'
require 'lock_jar/domain/artifact'

describe LockJar::Domain::Dsl do
  describe '.create' do
    it 'should load a Jarfile' do
      jarfile = LockJar::Domain::Dsl.create('spec/fixtures/Jarfile')

      jarfile.local_repository.should eql '~/.m2/repository'
      expect(jarfile.artifacts['default'][0]).to eq LockJar::Domain::Jar.new('org.apache.mina:mina-core:2.0.4')
      expect(jarfile.artifacts['default'][1]).to eq LockJar::Domain::Local.new('spec/fixtures/naether-0.13.0.jar')
      jarfile.artifacts['default'][2].path.should eql 'spec/pom.xml'
      jarfile.artifacts['default'][3].should be_nil

      expect(jarfile.artifacts['development'][0]).to eq LockJar::Domain::Jar.new('com.typesafe:config:jar:0.5.0')
      jarfile.artifacts['development'][1].should be_nil

      expect(jarfile.artifacts['test'][0]).to eq LockJar::Domain::Jar.new('junit:junit:jar:4.10')
      jarfile.artifacts['test'][1].should be_nil

      jarfile.remote_repositories.should eql(['http://mirrors.ibiblio.org/pub/mirrors/maven2'])
    end

    it 'should load a block' do
      block = LockJar::Domain::Dsl.create do
        local_repo '~/.m2'
        repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'

        jar 'org.apache.mina:mina-core:2.0.4'
        local 'spec/fixtures/naether-0.13.0.jar'
        pom 'spec/pom.xml'

        group 'pirate' do
          jar 'org.apache.tomcat:servlet-api:jar:6.0.35'
        end

        group 'test' do
          jar 'junit:junit:jar:4.10'
        end
      end

      block.local_repository.should eql '~/.m2'
      expect(block.artifacts).to eq(
        'default' => [LockJar::Domain::Jar.new('org.apache.mina:mina-core:2.0.4'), LockJar::Domain::Local.new('spec/fixtures/naether-0.13.0.jar'), LockJar::Domain::Pom.new('spec/pom.xml')],
        'pirate' => [LockJar::Domain::Jar.new('org.apache.tomcat:servlet-api:jar:6.0.35')],
        'test' => [LockJar::Domain::Jar.new('junit:junit:jar:4.10')]
      )
      block.remote_repositories.should eql(['http://repository.jboss.org/nexus/content/groups/public-jboss'])
    end

    it 'should raise an error without arguments' do
      lambda { LockJar::Domain::Dsl.create }.should raise_error
    end
  end
end
