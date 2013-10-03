require 'spec_helper'
require 'lock_jar/domain/dsl'
require 'lock_jar/domain/pom_dsl'

describe LockJar::Domain::PomDsl do

  let(:parent) { LockJar::Domain::Dsl.create { } }

  context "set pom path" do

    it "should  by a block" do
      dsl = LockJar::Domain::PomDsl.new(parent) do
        pom_path 'test.xml'
      end

      dsl.pom.should eql 'test.xml'
    end

    it "should by param" do
      dsl = LockJar::Domain::PomDsl.new(parent, 'test.xml')

      dsl.pom.should eql 'test.xml'
    end
  end

  describe "uberjar" do

    let(:dsl) do
      dsl = LockJar::Domain::PomDsl.new(parent) do
        uberjar do
          explode_appenders "blah.file"
          explode_local_jars 'one.jar', 'two.jar'
          build_manifest do
            title 'title'
            version 'version'
            main_class 'main_class'
            created_by 'created_by'
            custom 'custom_key', 'custom_val'
          end

          before_jar do
            puts "test"
          end

          jar_name 'uberjar.jar'
        end
      end

      dsl.uberjars.first
    end

    it "should set appenders" do
      dsl.appenders.should eql ['blah.file']
    end

    it "should set local jars" do
      dsl.local_jars.should eql ['one.jar', 'two.jar']
    end

    it "should set manifest" do
      manifest = dsl.manifest.manifest
      manifest['Implementation-Title'].should eql 'title'
      manifest['Implementation-Version'].should eql 'version'
      manifest['Main-Class'].should eql 'main_class'
      manifest['Created-By'].should eql 'created_by'
      manifest['custom_key'].should eql 'custom_val'
    end

    it "should generate manifest text" do
      dsl.manifest.to_manifest.should eql "Implementation-Title: title\nImplementation-Version: version\nManifest-Version: 1.0\nMain-Class: main_class\ncustom_key: custom_val\nCreated-By: created_by\n"
    end

    it "should set before_jar" do
      dsl.callbacks[:before_jar].should_not be_nil
    end

    it "should set name" do
      dsl.name.should eql 'uberjar.jar'
    end
  end

end
