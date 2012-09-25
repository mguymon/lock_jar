require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))
require 'lib/lock_jar/rubygems'


describe LockJar::Rubygems do
  
  include LockJar::Rubygems::Kernel
  
  
  it "should set Registry" do
    lock_jar_registry.is_a?( LockJar::Registry ).should be_true
  end
    
  context "with require" do
    before(:all) do
      require 'solr_sail'
    end
    
    it "should have only loaded jars for solr_sail" do
     lock_jar_registry.loaded_gems.keys.should eql( 
        ["solr_sail"] )
    end
    
    it "should set classpath" do
      # XXX: Need a better assertion than this. The count will include previous tests
      $CLASSPATH.size.should eql( 71 )
    end
    
    it "should have correctly loaded SolrSail" do
      # manually load the jar packaged with the gem
      $CLASSPATH << SolrSail::DEFAULT_JAR
      
      # Start and stop solr
      # XXX: an assertion that the java is properly being called
      @server = com.tobedevoured.solrsail.JettyServer.new( 'tmp/solr' )
      @server.start
      @server.stop
    end
  end
end