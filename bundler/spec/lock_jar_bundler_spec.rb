require File.expand_path(File.join(File.dirname(__FILE__),'spec_helper'))

require 'lock_jar'
require 'lock_jar_bundler'

describe LockJar::Bundler, "#bundled_jarfiles" do
  it "should give a list of jarfile paths" do
    jar_files = LockJar::Bundler.bundled_jarfiles([:test])
    expect(jar_files).to eql [File.expand_path('spec/dummy_gem/Jarfile')]
  end

  it "should create a Jarfile.lock including bundler Jarfiles" do
    LockJar.lock( "spec/Jarfile", :local_repo => TEST_REPO, :lockfile => "#{TEMP_DIR}/BundledJarfile.lock" )
    lockfile = LockJar.read("#{TEMP_DIR}/BundledJarfile.lock")
    expect(lockfile.to_hash).to eql({
      "version"=>"0.10.0",
      "merged" => [File.expand_path('spec/dummy_gem/Jarfile')],
      "groups"=>{
          "default"=>{
              "dependencies"=> %w(
                com.google.guava:guava:jar:14.0.1
                com.metapossum:metapossum-scanner:jar:1.0.1
                com.tobedevoured.command:core:jar:0.3.2
                com.typesafe:config:jar:0.5.0
                commons-beanutils:commons-beanutils:jar:1.8.3
                commons-io:commons-io:jar:2.3
                commons-lang:commons-lang:jar:2.6
                commons-logging:commons-logging:jar:1.1.1
                org.modeshape:modeshape-common:jar:2.8.2.Final
                org.slf4j:slf4j-api:jar:1.6.6),
              "artifacts"=>[
                {"jar:com.tobedevoured.command:core:jar:0.3.2"=>{
                    "transitive"=>{
                        "commons-beanutils:commons-beanutils:jar:1.8.3"=>{
                            "commons-logging:commons-logging:jar:1.1.1"=>{}},
                        "com.typesafe:config:jar:0.5.0"=>{},
                        "com.metapossum:metapossum-scanner:jar:1.0.1"=>{
                            "commons-io:commons-io:jar:2.3"=>{}, "commons-lang:commons-lang:jar:2.6"=>{}},
                        "org.slf4j:slf4j-api:jar:1.6.6"=>{},
                        "org.modeshape:modeshape-common:jar:2.8.2.Final"=>{}
                    }
                }},
                {"jar:com.google.guava:guava:jar:14.0.1"=>{"transitive"=>{}}}
              ]
          }
      }
    })
  end
end