require File.expand_path(File.join(File.dirname(__FILE__),'spec_helper'))
require 'rubygems'
require 'lib/lock_jar'
require 'lib/lock_jar/domain/dsl'
require 'naether'

describe LockJar, "#lock" do    
  it "should create a lock file" do
    if File.exists?( 'tmp' )
      File.delete( 'tmp/Jarfile.lock' ) if File.exists?( 'tmp/Jarfile.lock' )
    else 
      Dir.mkdir( 'tmp' ) 
    end
    
    LockJar.lock( "spec/Jarfile", :local_repo => 'tmp/test-repo', :lockfile => 'tmp/Jarfile.lock' )
    File.exists?( 'tmp/Jarfile.lock' ).should be_true
    
    lockfile = LockJar.read('tmp/Jarfile.lock')
    lockfile.to_hash.should eql({
      "version"=> LockJar::VERSION, 
      "local_repository"=>"~/.m2/repository", 
      "groups"=>{
        "default"=>{
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
      },
      "remote_repositories" => ["http://mirrors.ibiblio.org/pub/mirrors/maven2", "http://repository.jboss.org/nexus/content/groups/public-jboss"]
    })
  end
  
  it "should replace dependencies with map" do
    dsl = LockJar::Domain::Dsl.create do
      map 'junit:junit:4.10', 'tmp'
      jar 'junit:junit:4.10'
    end
    
    LockJar.lock( dsl, :local_repo => 'tmp/test-repo', :lockfile => 'tmp/Jarfile.lock' )
    lockfile = LockJar.read('tmp/Jarfile.lock')
    lockfile.to_hash.should eql({
      "version"=> LockJar::VERSION, 
      "maps"=>{"junit:junit:4.10"=>["tmp"]}, 
      "groups"=>{
        "default"=>{
          "dependencies"=>["junit:junit:jar:4.10", "org.hamcrest:hamcrest-core:jar:1.1"], 
          "artifacts"=>[{
            "jar:junit:junit:jar:4.10"=>{
              "transitive"=>{"org.hamcrest:hamcrest-core:jar:1.1"=>{}}}
          }]
        }
      },
      "remote_repositories" => ["http://mirrors.ibiblio.org/pub/mirrors/maven2", "http://repository.jboss.org/nexus/content/groups/public-jboss"]
    })      
  end
  
  it "should exclude excludes from dependencies" do
    dsl = LockJar::Domain::Dsl.create do
      exclude 'commons-logging', 'logkit'
      jar 'opensymphony:oscache:jar:2.4.1'
    end
    
    LockJar.lock( dsl, :local_repo => 'tmp/test-repo', :lockfile => 'tmp/Jarfile.lock' )
    File.exists?( 'tmp/Jarfile.lock' ).should be_true
    lockfile = LockJar.read('tmp/Jarfile.lock')
    lockfile.to_hash.should eql({
      "version"=> LockJar::VERSION, 
      "excludes"=>["commons-logging", "logkit"], 
      "groups"=>{
        "default"=>{
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
      },
      "remote_repositories" => ["http://mirrors.ibiblio.org/pub/mirrors/maven2", "http://repository.jboss.org/nexus/content/groups/public-jboss"]
    })
    
  end
  
  
  it "should lock using a block" do
    LockJar.lock( :local_repo => 'tmp/test-repo', :lockfile => 'tmp/NoRepoJarfile.lock' ) do
      jar "org.eclipse.jetty:jetty-servlet:8.1.3.v20120416"
    end
    
    File.exists?( 'tmp/NoRepoJarfile.lock' ).should be_true
    
    lockfile = LockJar.read('tmp/NoRepoJarfile.lock')
    lockfile.to_hash.should eql({
      "version"=> LockJar::VERSION, 
      "groups"=>{
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
    })
  end
end

describe LockJar, "#install" do     
  it "should install jars" do
    
    LockJar.lock( "spec/Jarfile", :download_artifacts => false, :local_repo => 'tmp/test-repo-install', :lockfile => 'tmp/Jarfile.lock' )
          
    jars = LockJar.install( 'tmp/Jarfile.lock', ['default'], :local_repo => 'tmp/test-repo-install' )
    jars.should eql([
      File.expand_path("tmp/test-repo-install/ch/qos/logback/logback-classic/0.9.24/logback-classic-0.9.24.jar"), 
      File.expand_path("tmp/test-repo-install/ch/qos/logback/logback-core/0.9.24/logback-core-0.9.24.jar"), 
      File.expand_path("tmp/test-repo-install/com/metapossum/metapossum-scanner/1.0/metapossum-scanner-1.0.jar"), 
      File.expand_path("tmp/test-repo-install/com/slackworks/modelcitizen/0.2.2/modelcitizen-0.2.2.jar"), 
      File.expand_path("tmp/test-repo-install/commons-beanutils/commons-beanutils/1.8.3/commons-beanutils-1.8.3.jar"), 
      File.expand_path("tmp/test-repo-install/commons-io/commons-io/1.4/commons-io-1.4.jar"), 
      File.expand_path("tmp/test-repo-install/commons-lang/commons-lang/2.6/commons-lang-2.6.jar"), 
      File.expand_path("tmp/test-repo-install/commons-logging/commons-logging/1.1.1/commons-logging-1.1.1.jar"), 
      File.expand_path("tmp/test-repo-install/org/apache/mina/mina-core/2.0.4/mina-core-2.0.4.jar"), 
      File.expand_path("tmp/test-repo-install/org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar") 

    ])
  end
  
end

describe LockJar, "#list" do     
  it "should list jars" do
    
    LockJar.lock( "spec/Jarfile", :local_repo => 'tmp/test-repo', :lockfile => 'tmp/Jarfile.lock' )
          
    jars = LockJar.list( 'tmp/Jarfile.lock', ['default', 'development', 'bad scope'], :local_repo => 'tmp/test-repo' )
    jars.should eql([
      "ch.qos.logback:logback-classic:jar:0.9.24", "ch.qos.logback:logback-core:jar:0.9.24", 
       "com.metapossum:metapossum-scanner:jar:1.0", "com.slackworks:modelcitizen:jar:0.2.2", 
       "commons-beanutils:commons-beanutils:jar:1.8.3", "commons-io:commons-io:jar:1.4", 
       "commons-lang:commons-lang:jar:2.6", "commons-logging:commons-logging:jar:1.1.1", 
       "org.apache.mina:mina-core:jar:2.0.4", 
       "org.slf4j:slf4j-api:jar:1.6.1", "com.typesafe:config:jar:0.5.0" ])
  end
  
  it "should replace dependencies with maps" do
    dsl = LockJar::Domain::Dsl.create do
      map 'junit:junit', 'tmp'
      jar 'junit:junit:4.10'
    end
    
    LockJar.lock( dsl, :local_repo => 'tmp/test-repo', :lockfile => 'tmp/ListJarfile.lock' )
    paths = LockJar.list( 'tmp/ListJarfile.lock', :local_repo => 'tmp/test-repo' )
    paths.should eql( [ "tmp", "org.hamcrest:hamcrest-core:jar:1.1"] ) 
  end
  
  it "should replace dependencies with maps and get local paths" do
    dsl = LockJar::Domain::Dsl.create do
      map 'junit:junit', 'tmp'
      jar 'junit:junit:4.10'
    end
    
    LockJar.lock( dsl, :local_repo => 'tmp/test-repo', :lockfile => 'tmp/ListJarfile.lock' )
    paths = LockJar.list( 'tmp/ListJarfile.lock', :local_repo => 'tmp/test-repo' )
    paths.should eql( [ "tmp", "org.hamcrest:hamcrest-core:jar:1.1"] ) 
  end
end
    
describe LockJar, "#load" do     
  it "by Jarfile.lock" do
    if Naether.platform == 'java'
      lambda { java_import 'org.apache.mina.core.IoUtil' }.should raise_error
    else
      lambda { Rjb::import('org.apache.mina.core.IoUtil') }.should raise_error
    end
    

    LockJar.lock( "spec/Jarfile", :local_repo => 'tmp/test-repo', :lockfile => 'tmp/Jarfile.lock' )
    
    jars = LockJar.load( 'tmp/Jarfile.lock', ['default'], :local_repo => 'tmp/test-repo' )
    LockJar::Registry.instance.lockfile_registered?( "tmp/Jarfile.lock" ).should be_false
    
    jars.should eql([
      File.expand_path("tmp/test-repo/ch/qos/logback/logback-classic/0.9.24/logback-classic-0.9.24.jar"), 
      File.expand_path("tmp/test-repo/ch/qos/logback/logback-core/0.9.24/logback-core-0.9.24.jar"), 
      File.expand_path("tmp/test-repo/com/metapossum/metapossum-scanner/1.0/metapossum-scanner-1.0.jar"), 
      File.expand_path("tmp/test-repo/com/slackworks/modelcitizen/0.2.2/modelcitizen-0.2.2.jar"), 
      File.expand_path("tmp/test-repo/commons-beanutils/commons-beanutils/1.8.3/commons-beanutils-1.8.3.jar"), 
      File.expand_path("tmp/test-repo/commons-io/commons-io/1.4/commons-io-1.4.jar"), 
      File.expand_path("tmp/test-repo/commons-lang/commons-lang/2.6/commons-lang-2.6.jar"), 
      File.expand_path("tmp/test-repo/commons-logging/commons-logging/1.1.1/commons-logging-1.1.1.jar"), 
      File.expand_path("tmp/test-repo/org/apache/mina/mina-core/2.0.4/mina-core-2.0.4.jar"), 
      File.expand_path("tmp/test-repo/org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar"),
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
