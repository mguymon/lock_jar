require File.expand_path(File.join(File.dirname(__FILE__),'spec_helper'))
require 'rubygems'
require 'lib/lock_jar'
require 'lib/lock_jar/domain/dsl'
require 'naether'

describe LockJar do

  before do
    LockJar::Runtime.instance.reset!

    if File.exists?( TEMP_DIR )
      File.delete( "#{TEMP_DIR}/Jarfile.lock" ) if File.exists?( "#{TEMP_DIR}/Jarfile.lock" )
    else
      Dir.mkdir( TEMP_DIR )
    end
  end

  describe "#lock" do
    context "creates a lockfile" do
      let(:lockfile) do        
        LockJar.lock( lockjar_source, :local_repo => "#{TEMP_DIR}/test-repo", :lockfile => "#{TEMP_DIR}/Jarfile.lock" )
        File.exists?( "#{TEMP_DIR}/Jarfile.lock" ).should be_true
        LockJar.read("#{TEMP_DIR}/Jarfile.lock")
      end

      context "from Jarfile" do
        let(:lockjar_source) { "spec/fixtures/Jarfile" }

        let(:expected_version) { LockJar::VERSION }
        let(:expected_local_repository) { '~/.m2/repository' }
        let(:expected_excludes) { %w[commons-logging logkit] }
        let(:expected_remote_repositories) { %w[http://repo1.maven.org/maven2/] }
        let(:expected_groups) do
          {
            "default"=> {
              "locals"=>["spec/fixtures/naether-0.13.0.jar"],
              "dependencies"=>["ch.qos.logback:logback-classic:jar:0.9.24",
                "ch.qos.logback:logback-core:jar:0.9.24", "com.metapossum:metapossum-scanner:jar:1.0",
                "com.slackworks:modelcitizen:jar:0.2.2",
                "commons-beanutils:commons-beanutils:jar:1.8.3", "commons-io:commons-io:jar:1.4",
                "commons-lang:commons-lang:jar:2.6", "commons-logging:commons-logging:jar:1.1.1",
                 "org.apache.mina:mina-core:jar:2.0.4",
                "org.slf4j:slf4j-api:jar:1.6.1"],
              "artifacts"=>[{
                "jar:org.apache.mina:mina-core:jar:2.0.4"=>{
                  "transitive"=>{"org.slf4j:slf4j-api:jar:1.6.1"=>{}}
                }
              }, {
                "pom:spec/pom.xml"=>{
                  "scopes"=>["runtime", "compile"],
                  "transitive"=>{
                    "com.slackworks:modelcitizen:jar:0.2.2" => {
                      "com.metapossum:metapossum-scanner:jar:1.0"=>{
                        "commons-io:commons-io:jar:1.4"=>{}
                      },
                      "commons-beanutils:commons-beanutils:jar:1.8.3"=>{
                        "commons-logging:commons-logging:jar:1.1.1"=>{}
                      },
                      "ch.qos.logback:logback-classic:jar:0.9.24"=>{
                        "ch.qos.logback:logback-core:jar:0.9.24"=>{}
                      },
                      "commons-lang:commons-lang:jar:2.6"=>{}
                    }
                  }
                }
              }]
            },
            "development"=>{
              "dependencies"=>["com.typesafe:config:jar:0.5.0"],
              "artifacts"=>[{
                "jar:com.typesafe:config:jar:0.5.0"=>{"transitive"=>{}}
              }]
            },
            "test"=>{
              "dependencies"=>["junit:junit:jar:4.10", "org.hamcrest:hamcrest-core:jar:1.1"],
              "artifacts"=>[{
                "jar:junit:junit:jar:4.10"=>{
                  "transitive"=>{"org.hamcrest:hamcrest-core:jar:1.1"=>{}}}
              }]
            }
          }
        end
      end

      context "from a dsl" do

        describe '#map' do
          let(:lockjar_source) do
            LockJar::Domain::Dsl.create do
              map 'junit:junit:4.10', "#{TEMP_DIR}"
              jar 'junit:junit:4.10'
            end
          end

          let(:expected_version) { LockJar::VERSION }
          let(:expected_maps) { {"junit:junit:4.10"=>["#{TEMP_DIR}"] } }
          let(:expected_remote_repositories) do
            %w[
                http://repo1.maven.org/maven2/
              ]
          end
          let(:expected_groups) do
            {
              "default"=>{
                "dependencies"=>["junit:junit:jar:4.10", "org.hamcrest:hamcrest-core:jar:1.1"],
                "artifacts"=>[{
                  "jar:junit:junit:jar:4.10"=>{
                    "transitive"=>{"org.hamcrest:hamcrest-core:jar:1.1"=>{}}}
                }]
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
          let(:expected_excludes) { %w[commons-logging logkit] }
          let(:expected_remote_repositories) { %w[http://repo1.maven.org/maven2/] }
          let(:expected_groups) do
            { "default" =>
              {
                "dependencies"=>[
                  "avalon-framework:avalon-framework:jar:4.1.3", "javax.jms:jms:jar:1.1",
                  "javax.servlet:servlet-api:jar:2.3", "log4j:log4j:jar:1.2.12",
                  "opensymphony:oscache:jar:2.4.1"],
                "artifacts"=>[{
                  "jar:opensymphony:oscache:jar:2.4.1"=>{
                    "transitive"=>{
                      "commons-logging:commons-logging:jar:1.1"=>{
                        "logkit:logkit:jar:1.0.1"=>{},
                        "log4j:log4j:jar:1.2.12"=>{},
                        "avalon-framework:avalon-framework:jar:4.1.3"=>{}
                      },
                      "javax.jms:jms:jar:1.1"=>{},
                      "javax.servlet:servlet-api:jar:2.3"=>{}
                    }
                  }
                }]
              }
            }
          end

          it_behaves_like 'a lockfile'
        end
      end

      context 'from a block' do
        let(:lockfile) do
          LockJar.lock( :local_repo => "#{TEMP_DIR}/test-repo", :lockfile => "#{TEMP_DIR}/NoRepoJarfile.lock" ) do
            jar "org.eclipse.jetty:jetty-servlet:8.1.3.v20120416"
          end

          File.exists?( "#{TEMP_DIR}/NoRepoJarfile.lock" ).should be_true

          LockJar.read("#{TEMP_DIR}/NoRepoJarfile.lock")
        end

        let(:expected_version) { LockJar::VERSION }
        let(:expected_remote_repositories) { %w[http://repo1.maven.org/maven2/] }
        let(:expected_groups) do
          {
            "default"=>{
              "dependencies"=>["org.eclipse.jetty.orbit:javax.servlet:jar:3.0.0.v201112011016",
                "org.eclipse.jetty:jetty-continuation:jar:8.1.3.v20120416",
                "org.eclipse.jetty:jetty-http:jar:8.1.3.v20120416",
                "org.eclipse.jetty:jetty-io:jar:8.1.3.v20120416",
                "org.eclipse.jetty:jetty-security:jar:8.1.3.v20120416",
                "org.eclipse.jetty:jetty-server:jar:8.1.3.v20120416",
                "org.eclipse.jetty:jetty-servlet:jar:8.1.3.v20120416",
                "org.eclipse.jetty:jetty-util:jar:8.1.3.v20120416"],
              "artifacts"=>[{
                "jar:org.eclipse.jetty:jetty-servlet:jar:8.1.3.v20120416"=>{
                  "transitive"=>{
                    "org.eclipse.jetty:jetty-security:jar:8.1.3.v20120416"=>{
                      "org.eclipse.jetty:jetty-server:jar:8.1.3.v20120416"=>{
                        "org.eclipse.jetty.orbit:javax.servlet:jar:3.0.0.v201112011016"=>{},
                        "org.eclipse.jetty:jetty-continuation:jar:8.1.3.v20120416"=>{},
                        "org.eclipse.jetty:jetty-http:jar:8.1.3.v20120416"=>{
                          "org.eclipse.jetty:jetty-io:jar:8.1.3.v20120416"=>{
                            "org.eclipse.jetty:jetty-util:jar:8.1.3.v20120416"=>{}
                          }
                        }
                      }
                    }
                  }
                }
              }]
            }
          }
        end

        it_behaves_like 'a lockfile'
      end
    end
  end

  describe "#install" do
    it "should install jars" do

      LockJar.lock( "spec/fixtures/Jarfile", :download_artifacts => false, :local_repo => "#{TEMP_DIR}/test-repo-install", :lockfile => "#{TEMP_DIR}/Jarfile.lock" )

      jars = LockJar.install( "#{TEMP_DIR}/Jarfile.lock", ['default'], :local_repo => "#{TEMP_DIR}/test-repo-install" )
      jars.should eql([
        File.expand_path("#{TEMP_DIR}/test-repo-install/ch/qos/logback/logback-classic/0.9.24/logback-classic-0.9.24.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/ch/qos/logback/logback-core/0.9.24/logback-core-0.9.24.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/com/metapossum/metapossum-scanner/1.0/metapossum-scanner-1.0.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/com/slackworks/modelcitizen/0.2.2/modelcitizen-0.2.2.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/commons-beanutils/commons-beanutils/1.8.3/commons-beanutils-1.8.3.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/commons-io/commons-io/1.4/commons-io-1.4.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/commons-lang/commons-lang/2.6/commons-lang-2.6.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/commons-logging/commons-logging/1.1.1/commons-logging-1.1.1.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/org/apache/mina/mina-core/2.0.4/mina-core-2.0.4.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo-install/org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar")
      ])
    end

  end

  describe "#register_jarfile" do
    after do
      LockJar.reset_registered_jarfiles
    end

    it 'should add an existing jarfiles in order' do
      LockJar.register_jarfile "spec/fixtures/Jarfile"
      LockJar.register_jarfile "spec/fixtures/Jarfile2"
      LockJar.registered_jarfiles.should ==
        ["spec/fixtures/Jarfile", "spec/fixtures/Jarfile2"]
    end

    it 'should not add a missing jarfile' do
      proc {
        LockJar.register_jarfile "spec/fixtures/NotAJarfile"
      }.should raise_exception(RuntimeError,
                               "Jarfile not found: spec/fixtures/NotAJarfile")
    end
  end

  describe "#lock_registered_jarfiles" do
    after do
      LockJar.reset_registered_jarfiles
    end

    it 'should work with no jarfiles' do
      lockfile = "#{TEMP_DIR}/LRJJarfile1.lock"
      File.unlink lockfile if File.exists? lockfile
      result = LockJar.lock_registered_jarfiles lockfile: lockfile
      result.should be_nil
      File.exists?(lockfile).should be_false
    end

    it 'should merge all jarfiles' do
      LockJar.register_jarfile "spec/fixtures/Jarfile"
      LockJar.register_jarfile "spec/fixtures/Jarfile2"
      lockfile = "#{TEMP_DIR}/LRJJarfile2.lock"
      File.unlink lockfile if File.exists? lockfile
      result = LockJar.lock_registered_jarfiles lockfile: lockfile
      artifacts = result.to_hash['groups']['default']['artifacts'].flat_map { |a| a.keys }
      artifacts.should == [
        "jar:org.apache.mina:mina-core:jar:2.0.4",
        "pom:spec/pom.xml",
        "jar:org.eclipse.jetty:jetty-servlet:jar:8.1.3.v20120416"
      ]
      File.exists?(lockfile).should be_true
    end
  end

  describe "#list" do
    it "should list jars" do

      LockJar.lock( "spec/fixtures/Jarfile", :local_repo => "#{TEMP_DIR}/test-repo", :lockfile => "#{TEMP_DIR}/Jarfile.lock" )

      jars = LockJar.list( "#{TEMP_DIR}/Jarfile.lock", ['default', 'development', 'bad scope'], :local_repo => "#{TEMP_DIR}/test-repo" )
      jars.should eql([
        "ch.qos.logback:logback-classic:jar:0.9.24", "ch.qos.logback:logback-core:jar:0.9.24",
         "com.metapossum:metapossum-scanner:jar:1.0", "com.slackworks:modelcitizen:jar:0.2.2",
         "commons-beanutils:commons-beanutils:jar:1.8.3", "commons-io:commons-io:jar:1.4",
         "commons-lang:commons-lang:jar:2.6", "commons-logging:commons-logging:jar:1.1.1",
         "org.apache.mina:mina-core:jar:2.0.4",
         "org.slf4j:slf4j-api:jar:1.6.1", "spec/fixtures/naether-0.13.0.jar", "com.typesafe:config:jar:0.5.0" ])
    end

    it "should replace dependencies with maps" do
      dsl = LockJar::Domain::Dsl.create do
        map 'junit:junit', "#{TEMP_DIR}"
        jar 'junit:junit:4.10'
      end

      LockJar.lock( dsl, :local_repo => "#{TEMP_DIR}/test-repo", :lockfile => "#{TEMP_DIR}/ListJarfile.lock")
      paths = LockJar.list( "#{TEMP_DIR}/ListJarfile.lock", :local_repo => "#{TEMP_DIR}/test-repo" )
      paths.should eql( [ "#{TEMP_DIR}", "org.hamcrest:hamcrest-core:jar:1.1"] )
    end

    it "should replace dependencies with maps and get local paths" do
      dsl = LockJar::Domain::Dsl.create do
        map 'junit:junit', "#{TEMP_DIR}"
        jar 'junit:junit:4.10'
      end

      LockJar.lock( dsl, :local_repo => "#{TEMP_DIR}/test-repo", :lockfile => "#{TEMP_DIR}/ListJarfile.lock" )
      paths = LockJar.list( "#{TEMP_DIR}/ListJarfile.lock", :local_repo => "#{TEMP_DIR}/test-repo" )
      paths.should eql( [ "#{TEMP_DIR}", "org.hamcrest:hamcrest-core:jar:1.1"] )
    end
  end

  describe "#load" do
    it "by Jarfile.lock" do
      if Naether.platform == 'java'
        lambda { java_import 'org.apache.mina.core.IoUtil' }.should raise_error
      else
        lambda { Rjb::import('org.apache.mina.core.IoUtil') }.should raise_error
      end


      LockJar.lock( "spec/fixtures/Jarfile", :local_repo => "#{TEMP_DIR}/test-repo", :lockfile => "#{TEMP_DIR}/Jarfile.lock" )

      jars = LockJar.load( "#{TEMP_DIR}/Jarfile.lock", ['default'], :local_repo => "#{TEMP_DIR}/test-repo" )
      LockJar::Registry.instance.lockfile_registered?( "#{TEMP_DIR}/Jarfile.lock" ).should be_false

      jars.should eql([
        "spec/fixtures/naether-0.13.0.jar",
        File.expand_path("#{TEMP_DIR}/test-repo/ch/qos/logback/logback-classic/0.9.24/logback-classic-0.9.24.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/ch/qos/logback/logback-core/0.9.24/logback-core-0.9.24.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/com/metapossum/metapossum-scanner/1.0/metapossum-scanner-1.0.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/com/slackworks/modelcitizen/0.2.2/modelcitizen-0.2.2.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/commons-beanutils/commons-beanutils/1.8.3/commons-beanutils-1.8.3.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/commons-io/commons-io/1.4/commons-io-1.4.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/commons-lang/commons-lang/2.6/commons-lang-2.6.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/commons-logging/commons-logging/1.1.1/commons-logging-1.1.1.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/org/apache/mina/mina-core/2.0.4/mina-core-2.0.4.jar"),
        File.expand_path("#{TEMP_DIR}/test-repo/org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar"),
      ])
      if Naether.platform == 'java'
        lambda { java_import 'org.apache.mina.core.IoUtil' }.should_not raise_error
      else
        lambda { Rjb::import('org.apache.mina.core.IoUtil') }.should_not raise_error
      end


    end

    it "by block with resolve option" do
      if Naether.platform == 'java'
        lambda { java_import 'org.modeshape.common.math.Duration' }.should raise_error
      else
        lambda { Rjb::import('org.modeshape.common.math.Duration') }.should raise_error
      end

      jars = LockJar.load(:local_repo => TEST_REPO, :resolve => true) do
        jar 'org.modeshape:modeshape-common:3.4.0.Final'
      end

      jars.should eql( [File.expand_path(TEST_REPO + "/org/modeshape/modeshape-common/3.4.0.Final/modeshape-common-3.4.0.Final.jar")] )

      if Naether.platform == 'java'
        lambda { java_import 'org.modeshape.common.math.Duration' }.should_not raise_error
      else
        lambda { Rjb::import('org.modeshape.common.math.Duration') }.should_not raise_error
      end
    end
  end

  describe "#extract_args" do
    # Certain argument combinations can't really be tested

    it 'should have the right defaults for :lockfile' do
      LockJar.send(:extract_args, :lockfile, []).should == ['Jarfile.lock', ['default'], {}]
    end

    it 'should have the right defaults for :jarfile' do
      LockJar.send(:extract_args, :jarfile, []).should == ['Jarfile', ['default'], {}]
    end

    it 'should not have a default filename if a block is given' do
      blk = proc {}
      LockJar.send(:extract_args, :jarfile, [], &blk).should == [nil, ['default'], {}]
      LockJar.send(:extract_args, :lockfile, [], &blk).should == [nil, ['default'], {}]
    end

    it 'should use the :lockfile opt when lockfile is requested' do
      LockJar.send(:extract_args, :lockfile, [{lockfile: "LF"}]).should == ["LF", ['default'], {lockfile: "LF"}]
    end
    it 'should not use the :lockfile opt when jarfile is requested' do
      LockJar.send(:extract_args, :jarfile, [{lockfile: "LF"}]).should == ["Jarfile", ['default'], {lockfile: "LF"}]
    end
    it 'should not use the :lockfile opt when a lockfile provided' do
      LockJar.send(:extract_args, :lockfile, ["MyLF", {lockfile: "LF"}]).should == ["MyLF", ['default'], {lockfile: "LF"}]
    end
  end
end
