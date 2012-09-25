require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
require 'lib/lock_jar/class_loader'


describe LockJar::ClassLoader, "#isolate" do
  before( :all ) do
    # Generate the IsolateJarfile.lock 
    LockJar.lock( :lockfile => 'tmp/IsolateJarfile.lock' ) do
     jar 'org.apache.commons:commons-email:1.2'
    end
  
  end
  
  it "should load jars without changing the parent classpath" do
    unless $CLASSPATH.nil?
      $CLASSPATH.to_a.join(' ').should_not =~ /commons-email-1\.2\.jar/
    end
    
    email = LockJar::ClassLoader.new( 'tmp/IsolateJarfile.lock' ).isolate do
        email = create( 'org.apache.commons.mail.SimpleEmail' )
        email.setSubject( 'test subject' )                       
        email
    end
    
    email.getSubject().should eql 'test subject'
    
    unless $CLASSPATH.nil?
      $CLASSPATH.to_a.join(' ').should_not =~ /commons-email-1\.2\.jar/
    end
    
    expect { org.apache.commons.mail.SimpleEmail.new }.to raise_error
  end
end