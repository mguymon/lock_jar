require 'spec_helper'

require 'lock_jar/domain/dsl_helper'

describe LockJar::Domain::DslHelper do
  it 'should merge dsl' do
    block1 = LockJar::Domain::Dsl.create do
      repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'

      jar 'org.apache.mina:mina-core:2.0.4'
      pom 'spec/pom.xml'

      group 'runtime' do
        jar 'org.apache.tomcat:servlet-api:jar:6.0.35'
      end

      group 'test' do
        jar 'junit:junit:jar:4.10'
      end
    end

    block2 = LockJar::Domain::Dsl.create do
      repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
      repository 'http://new-repo'

      jar 'org.apache.mina:mina-core:2.0.4'
      jar 'compile-jar'

      group 'runtime' do
        jar 'runtime-jar'
        pom 'runtime-pom.xml'
      end

      group 'test' do
        jar 'test-jar'
        pom 'test-pom.xml'
      end
    end

    dsl = LockJar::Domain::DslHelper.merge(block1, block2)

    dsl.artifacts['default'].should =~ [
      LockJar::Domain::Jar.new('org.apache.mina:mina-core:2.0.4'),
      LockJar::Domain::Pom.new('spec/pom.xml', %w(runtime compile)),
      LockJar::Domain::Jar.new('compile-jar')
    ]
    dsl.remote_repositories.should eql(['http://repository.jboss.org/nexus/content/groups/public-jboss', 'http://new-repo'])
  end
end
