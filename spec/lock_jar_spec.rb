require 'spec_helper'
require 'lib/lock_jar'
require 'lib/lock_jar/domain/dsl'
require 'naether'

describe LockJar do
  include Spec::Helpers

  let(:local_repo) { "#{TEMP_DIR}/test-repo" }

  before do
    LockJar::Runtime.instance.reset!

    if File.exist?(TEMP_DIR)
      remove_file("#{TEMP_DIR}/Jarfile.lock")
    else
      Dir.mkdir(TEMP_DIR)
    end
  end

  describe '#lock' do
    context 'creates a lockfile' do
      let(:lockfile) do
        LockJar.lock(lockjar_source, local_repo: local_repo, lockfile: "#{TEMP_DIR}/Jarfile.lock")
        expect(File).to exist("#{TEMP_DIR}/Jarfile.lock")
        LockJar.read("#{TEMP_DIR}/Jarfile.lock")
      end
      let(:test_dependencies) { %w(com.beust:jcommander:jar:1.48 org.beanshell:bsh:jar:2.0b4 org.testng:testng:jar:6.9.10) }
      let(:test_artifacts) do
        [
          {
            'jar:org.testng:testng:jar:6.9.10' => {
              'transitive' => {
                'com.beust:jcommander:jar:1.48' => {},
                'org.beanshell:bsh:jar:2.0b4' => {}
              }
            }
          }
        ]
      end

      context 'from Jarfile' do
        let(:lockjar_source) { 'spec/fixtures/Jarfile' }
        let(:expected_version) { LockJar::VERSION }
        let(:expected_local_repository) { '~/.m2/repository' }
        let(:expected_excludes) { %w(commons-logging logkit) }
        let(:expected_remote_repositories) { %w(http://repo1.maven.org/maven2/) }
        let(:expected_groups) do
          {
            'default' => {
              'locals' => ['spec/fixtures/naether-0.13.0.jar'],
              'dependencies' => %w(
                ch.qos.logback:logback-classic:jar:0.9.24
                ch.qos.logback:logback-core:jar:0.9.24 com.metapossum:metapossum-scanner:jar:1.0
                com.tobedevoured.modelcitizen:core:jar:0.8.1
                commons-beanutils:commons-beanutils:jar:1.8.3 commons-io:commons-io:jar:1.4
                commons-lang:commons-lang:jar:2.6 commons-logging:commons-logging:jar:1.1.1
                org.apache.mina:mina-core:jar:2.0.4
                org.slf4j:slf4j-api:jar:1.6.1
              ),
              'artifacts' => [
                {
                  'jar:org.apache.mina:mina-core:jar:2.0.4' => {
                    'transitive' => { 'org.slf4j:slf4j-api:jar:1.6.1' => {} }
                  }
                },
                {
                  'pom:spec/pom.xml' => {
                    'scopes' => %w(runtime compile),
                    'transitive' => {
                      'com.tobedevoured.modelcitizen:core:jar:0.8.1' => {
                        'com.metapossum:metapossum-scanner:jar:1.0' => {
                          'commons-io:commons-io:jar:1.4' => {}
                        },
                        'commons-beanutils:commons-beanutils:jar:1.8.3' => {
                          'commons-logging:commons-logging:jar:1.1.1' => {}
                        },
                        'ch.qos.logback:logback-classic:jar:0.9.24' => {
                          'ch.qos.logback:logback-core:jar:0.9.24' => {}
                        },
                        'commons-lang:commons-lang:jar:2.6' => {}
                      }
                    }
                  }
                }
              ]
            },
            'development' => {
              'dependencies' => ['com.typesafe:config:jar:0.5.0'],
              'artifacts' => [
                { 'jar:com.typesafe:config:jar:0.5.0' => { 'transitive' => {} } }
              ]
            },
            'test' => {
              'dependencies' => test_dependencies,
              'artifacts' => test_artifacts
            }
          }
        end
      end

      context 'from a dsl' do
        describe '#without_default_maven_repo' do
          let(:lockjar_source) do
            LockJar::Domain::Dsl.create do
              without_default_maven_repo
              remote_repo 'https://repository.jboss.org/nexus/content/groups/public'
              jar 'org.jboss.logging:jboss-logging:3.1.0.GA'
            end
          end

          let(:expected_version) { LockJar::VERSION }
          let(:expected_remote_repositories) { ['https://repository.jboss.org/nexus/content/groups/public'] }
          let(:expected_groups) do
            {
              'default' => {
                'dependencies' => ['org.jboss.logging:jboss-logging:jar:3.1.0.GA'],
                'artifacts' => [
                  { 'jar:org.jboss.logging:jboss-logging:jar:3.1.0.GA' => { 'transitive' => {} } }
                ]
              }
            }
          end

          it_behaves_like 'a lockfile'
        end

        describe '#map' do
          let(:lockjar_source) do
            LockJar::Domain::Dsl.create do
              map 'org.testng:testng:jar:6.9.10', 'path/to/jar'
              jar 'org.testng:testng:jar:6.9.10'
            end
          end

          let(:expected_version) { LockJar::VERSION }
          let(:expected_maps) { { 'org.testng:testng:jar:6.9.10' => ['path/to/jar'] } }
          let(:expected_remote_repositories) { ['http://repo1.maven.org/maven2/'] }
          let(:expected_groups) do
            {
              'default' => {
                'dependencies' => test_dependencies,
                'artifacts' => test_artifacts
              }
            }
          end

          it_behaves_like 'a lockfile'
        end

        describe '#exclude' do
          let(:lockjar_source) do
            LockJar::Domain::Dsl.create do
              remote_repo 'https://repository.jboss.org/nexus/content/groups/public'
              exclude 'commons-logging', 'logkit'
              jar 'opensymphony:oscache:jar:2.4.1'
            end
          end

          let(:expected_version) { LockJar::VERSION }
          let(:expected_excludes) { %w(commons-logging logkit) }
          let(:expected_remote_repositories) { %w(http://repo1.maven.org/maven2/ https://repository.jboss.org/nexus/content/groups/public) }
          let(:expected_groups) do
            {
              'default' => {
                'dependencies' => %w(
                  avalon-framework:avalon-framework:jar:4.1.3 javax.jms:jms:jar:1.1
                  javax.servlet:servlet-api:jar:2.3 log4j:log4j:jar:1.2.12
                  opensymphony:oscache:jar:2.4.1
                ),
                'artifacts' => [
                  {
                    'jar:opensymphony:oscache:jar:2.4.1' => {
                      'transitive' => {
                        'commons-logging:commons-logging:jar:1.1' => {
                          'logkit:logkit:jar:1.0.1' => {},
                          'log4j:log4j:jar:1.2.12' => {},
                          'avalon-framework:avalon-framework:jar:4.1.3' => {}
                        },
                        'javax.jms:jms:jar:1.1' => {},
                        'javax.servlet:servlet-api:jar:2.3' => {}
                      }
                    }
                  }
                ]
              }
            }
          end

          it_behaves_like 'a lockfile'
        end
      end

      context 'from a block' do
        let(:lockfile) do
          LockJar.lock(local_repo: local_repo, lockfile: "#{TEMP_DIR}/NoRepoJarfile.lock") do
            jar 'org.eclipse.jetty:jetty-servlet:8.1.3.v20120416'
          end

          File.exist?("#{TEMP_DIR}/NoRepoJarfile.lock").should be_true

          LockJar.read("#{TEMP_DIR}/NoRepoJarfile.lock")
        end

        let(:expected_version) { LockJar::VERSION }
        let(:expected_remote_repositories) { %w(http://repo1.maven.org/maven2/) }
        let(:expected_groups) do
          {
            'default' => {
              'dependencies' => %w(
                org.eclipse.jetty.orbit:javax.servlet:jar:3.0.0.v201112011016
                org.eclipse.jetty:jetty-continuation:jar:8.1.3.v20120416
                org.eclipse.jetty:jetty-http:jar:8.1.3.v20120416
                org.eclipse.jetty:jetty-io:jar:8.1.3.v20120416
                org.eclipse.jetty:jetty-security:jar:8.1.3.v20120416
                org.eclipse.jetty:jetty-server:jar:8.1.3.v20120416
                org.eclipse.jetty:jetty-servlet:jar:8.1.3.v20120416
                org.eclipse.jetty:jetty-util:jar:8.1.3.v20120416),
              'artifacts' => [
                {
                  'jar:org.eclipse.jetty:jetty-servlet:jar:8.1.3.v20120416' => {
                    'transitive' => {
                      'org.eclipse.jetty:jetty-security:jar:8.1.3.v20120416' => {
                        'org.eclipse.jetty:jetty-server:jar:8.1.3.v20120416' => {
                          'org.eclipse.jetty.orbit:javax.servlet:jar:3.0.0.v201112011016' => {},
                          'org.eclipse.jetty:jetty-continuation:jar:8.1.3.v20120416' => {},
                          'org.eclipse.jetty:jetty-http:jar:8.1.3.v20120416' => {
                            'org.eclipse.jetty:jetty-io:jar:8.1.3.v20120416' => {
                              'org.eclipse.jetty:jetty-util:jar:8.1.3.v20120416' => {}
                            }
                          }
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        end

        it_behaves_like 'a lockfile'
      end
    end
  end

  describe '#install' do
    let(:repo_path) { "#{TEMP_DIR}/test-repo-install" }

    it 'should install jars' do
      LockJar.lock('spec/fixtures/Jarfile', download_artifacts: false, local_repo: "#{TEMP_DIR}/test-repo-install", lockfile: "#{TEMP_DIR}/Jarfile.lock")

      jars = LockJar.install("#{TEMP_DIR}/Jarfile.lock", ['default'], local_repo: "#{TEMP_DIR}/test-repo-install")
      jars.should eql([
        File.expand_path("#{repo_path}/com/google/guava/guava/14.0.1/guava-14.0.1.jar"),
        File.expand_path("#{repo_path}/org/apache/mina/mina-core/2.0.4/mina-core-2.0.4.jar"),
        File.expand_path("#{repo_path}/org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar")
      ])
    end
  end

  describe '#register_jarfile' do
    after do
      LockJar.reset_registered_jarfiles
    end

    it 'should add an existing jarfiles in order' do
      LockJar.register_jarfile 'spec/fixtures/Jarfile'
      LockJar.register_jarfile 'spec/fixtures/Jarfile2'
      LockJar.registered_jarfiles.keys.should ==
        ['spec/fixtures/Jarfile', 'spec/fixtures/Jarfile2']
    end

    it 'should not add a missing jarfile' do
      expect { LockJar.register_jarfile 'spec/fixtures/NotAJarfile' }.to(
        raise_error(RuntimeError, 'Jarfile not found: spec/fixtures/NotAJarfile')
      )
    end
  end

  describe '#lock_registered_jarfiles' do
    let(:lockfile) { "#{TEMP_DIR}/Jarfile.lock" }
    let(:lock_registered_jarfiles) { LockJar.lock_registered_jarfiles lockfile: lockfile }

    after do
      LockJar.reset_registered_jarfiles
    end

    context 'with LRJJarfile1.lock' do
      before do
        File.unlink lockfile if File.exist? lockfile
      end

      it 'should work with no jarfiles' do
        expect(lock_registered_jarfiles).to be_nil
        expect(File).to_not exist(lockfile)
      end
    end

    context 'with multiple lockfiles' do
      before do
        LockJar.register_jarfile 'spec/fixtures/Jarfile'
        LockJar.register_jarfile 'spec/fixtures/Jarfile2'
        File.unlink lockfile if File.exist? lockfile
      end

      it 'should dependencies from all jarfiles' do
        artifacts = lock_registered_jarfiles.to_hash['groups']['default']['artifacts'].flat_map(&:keys)
        artifacts.should eq %w(
          jar:org.apache.mina:mina-core:jar:2.0.4
          pom:spec/pom.xml
          jar:org.eclipse.jetty:jetty-servlet:jar:8.1.3.v20120416
        )
        expect(File).to exist(lockfile)
      end
    end

    context 'with gem lockfiles' do
      let(:gem_spec) { Gem::Specification.find_by_name('jarfile_gem') }
      let(:lock_registered_jarfiles) { LockJar.lock_registered_jarfiles lockfile: lockfile }

      before do
        LockJar.register_jarfile 'spec/fixtures/jarfile_gem/Jarfile', gem_spec
        File.unlink lockfile if File.exist? lockfile
      end

      it 'should have gem dependencies' do
        artifacts = lock_registered_jarfiles.to_hash['groups']['default']['artifacts'].flat_map(&:keys)
        artifacts.should eq %w(
          jar:commons-lang:commons-lang:jar:2.4
        )
        expect(File).to exist(lockfile)
      end
    end
  end

  describe '#list' do
    let(:lockfile) { "#{TEMP_DIR}/Jarfile.lock" }
    let(:lock) do
      LockJar.lock('spec/fixtures/Jarfile', local_repo: local_repo, lockfile: lockfile)
    end
    let(:jars) do
      lock
      LockJar.list(lockfile, ['default', 'development', 'bad scope'], local_repo: local_repo)
    end

    it 'should list jars' do
      jars.should eql(
        %w(
          com.google.guava:guava:jar:14.0.1 org.apache.mina:mina-core:jar:2.0.4
          org.slf4j:slf4j-api:jar:1.6.1 spec/fixtures/naether-0.13.0.jar
          com.typesafe:config:jar:0.5.0
        )
      )
    end

    context 'with a dsl' do
      let(:local_path) { "#{TEMP_DIR}/guava.jar" }
      let(:lockfile) { "#{TEMP_DIR}/ListJarfile.lock" }
      let(:dsl) do
        LockJar::Domain::Dsl.create do
          map 'com.google.guava:guava', "#{TEMP_DIR}/guava.jar"
          jar 'com.google.guava:guava:14.0.1'
        end
      end
      let(:paths) { LockJar.list(lockfile, local_repo: local_repo) }

      before { LockJar.lock(dsl, local_repo: local_repo, lockfile: lockfile) }

      it 'should replace dependencies with maps' do
        paths.should eql([local_path])
      end
    end

    context 'with resolve: false' do
      let(:jars) do
        lock
        LockJar.list(lockfile, local_repo: local_repo, resolve: false)
      end

      it 'should only list root dependencies' do
        jars.should eql(
          %w(
            org.apache.mina:mina-core:jar:2.0.4 spec/pom.xml spec/fixtures/naether-0.13.0.jar
          )
        )
      end
    end
  end

  describe '#load' do
    def expect_java_class_not_loaded(java_class)
      if Naether.platform == 'java'
        lambda { java_import java_class }.should raise_error
      else
        lambda { Rjb.import(java_class) }.should raise_error
      end
    end

    def expect_java_class_loaded(java_class)
      if Naether.platform == 'java'
        lambda { java_import java_class }.should_not raise_error
      else
        lambda { Rjb.import(java_class) }.should_not raise_error
      end
    end

    let(:repo_path) { "#{TEMP_DIR}/test-repo" }

    it 'by Jarfile.lock' do
      expect_java_class_not_loaded('org.apache.mina.core.IoUtil')

      LockJar.lock('spec/fixtures/Jarfile', local_repo: local_repo, lockfile: "#{TEMP_DIR}/Jarfile.lock")
      LockJar.load("#{TEMP_DIR}/Jarfile.lock", ['default'], local_repo: local_repo)
      expect(LockJar::Registry.instance.lockfile_registered?("#{TEMP_DIR}/Jarfile.lock")).to_not be
      expect_java_class_loaded('org.apache.mina.core.IoUtil')
    end

    it 'by block with resolve option' do
      expect_java_class_not_loaded('org.modeshape.common.math.Duration')

      LockJar.load(local_repo: TEST_REPO, resolve: true) do
        jar 'org.modeshape:modeshape-common:3.4.0.Final'
      end

      expect_java_class_loaded('org.modeshape.common.math.Duration')
    end

    context 'with disable option' do
      it 'consective calls to load should return nil' do
        LockJar.load(local_repo: TEST_REPO, resolve: true, disable: true) do
          jar 'org.modeshape:modeshape-common:3.4.0.Final'
        end

        jars = LockJar.load(local_repo: TEST_REPO, resolve: true) do
          jar 'another:jar:1.2.3'
        end
        expect(jars).to be_empty
      end
    end
  end

  describe '#extract_args' do
    # Certain argument combinations can't really be tested

    it 'should have the right defaults for :lockfile' do
      LockJar.send(:extract_args, :lockfile, []).should eq ['Jarfile.lock', ['default'], {}]
    end

    it 'should have the right defaults for :jarfile' do
      LockJar.send(:extract_args, :jarfile, []).should eq ['Jarfile', ['default'], {}]
    end

    it 'should not have a default filename if a block is given' do
      blk = proc {}
      LockJar.send(:extract_args, :jarfile, [], &blk).should eq [nil, ['default'], {}]
      LockJar.send(:extract_args, :lockfile, [], &blk).should eq [nil, ['default'], {}]
    end

    it 'should use the :lockfile opt when lockfile is requested' do
      LockJar.send(:extract_args, :lockfile, [{ lockfile: 'LF' }]).should eq ['LF', ['default'], { lockfile: 'LF' }]
    end
    it 'should not use the :lockfile opt when jarfile is requested' do
      LockJar.send(:extract_args, :jarfile, [{ lockfile: 'LF' }]).should eq ['Jarfile', ['default'], { lockfile: 'LF' }]
    end
    it 'should not use the :lockfile opt when a lockfile provided' do
      LockJar.send(:extract_args, :lockfile, ['MyLF', { lockfile: 'LF' }]).should eq ['MyLF', ['default'], { lockfile: 'LF' }]
    end
  end
end
