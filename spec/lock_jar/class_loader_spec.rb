require 'spec_helper'
require 'lock_jar/class_loader'

describe LockJar::ClassLoader, '#isolate' do
  if Naether.platform != 'java'
    pending 'need tests for RJB backed classloader'
  else
    it 'should create a SimpleEmail' do
      # Generate the IsolateJarfile.lock
      LockJar.lock(lockfile: "#{TEMP_DIR}/IsolateJarfile.lock") do
        jar 'org.apache.commons:commons-email:1.2'
      end

      email = LockJar::ClassLoader.new("#{TEMP_DIR}/IsolateJarfile.lock").isolate do
        email = new_instance('org.apache.commons.mail.SimpleEmail')
        email.setSubject('test subject')

        email
      end

      email.getSubject.should eql 'test subject'

      unless $CLASSPATH.nil?
        $CLASSPATH.to_a.join(' ').should_not =~ /commons-email-1\.2\.jar/
      end

      expect { org.apache.commons.mail.SimpleEmail.new }.to raise_error
    end

    it 'should create a JsonFactory and ObjectMapper' do
      # Generate the IsolateJarfile.lock
      LockJar.lock(lockfile: "#{TEMP_DIR}/IsolateJarfile.lock") do
        jar 'com.fasterxml.jackson.core:jackson-core:2.0.6'
        jar 'com.fasterxml.jackson.core:jackson-databind:2.0.6'
      end

      json = '{ "test1": "1test1", "test2": "2test2" }'

      map = LockJar::ClassLoader.new("#{TEMP_DIR}/IsolateJarfile.lock").isolate do
        factory = new_instance('com.fasterxml.jackson.core.JsonFactory')
        mapper = new_instance('com.fasterxml.jackson.databind.ObjectMapper', factory)
        mapper.readValue(json, java.util.Map.java_class)
      end

      map.get('test1').should eql '1test1'
      map.get('test2').should eql '2test2'

      unless $CLASSPATH.nil?
        $CLASSPATH.to_a.join(' ').should_not =~ /jackson-databind-2\.0\.6\.jar/
      end

      expect { com.fasterxml.jackson.core.JsonFactory.new }.to raise_error
    end
  end
end
