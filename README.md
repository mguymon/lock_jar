# LockJar

[![Build Status](https://secure.travis-ci.org/mguymon/lock_jar.png?branch=master)](http://travis-ci.org/mguymon/lock_jar)

LockJar manages Java Jars for Ruby. Powered by [Naether](https://github.com/mguymon/naether) to
 create a frankenstein of Bundler and Maven. A Jarfile ([example](https://github.com/mguymon/lock_jar/blob/master/spec/Jarfile)) is used to generate a Jarfile.lock that contains all the resolved jar dependencies. The Jarfile.lock can be used to populate the classpath.

LockJar can:
* Be used directly in MRI 1.8.7, 1.9.3, and JRuby 1.6.7, 1.6.8, 1.7.x
* From the [command line](https://github.com/mguymon/lock_jar/blob/master/README.md#command-line)
* [Triggered from a Gem install](https://github.com/mguymon/lock_jar/blob/master/README.md#gem-integration)
* [Integrated into Buildr](https://github.com/mguymon/lock_jar/blob/master/README.md#buildr-integration)
* Experimental [integration with Bundler](https://github.com/mguymon/lock_jar/blob/master/README.md#bundler-integration)

https://github.com/mguymon/lock_jar

[RDoc](http://rubydoc.info/gems/lock_jar/frames)

## Install

    gem install lock_jar

## Ruby Usage

JRuby is natively supported. Ruby 1.8.7 and 1.9.3 uses [Rjb](http://rjb.rubyforge.org/) to proxy over JNI.

### Jarfile

A Jarfile is a simple file using a Ruby DSL for defining a project's dependencies using the following 
methods:

* **local_repo( path )**: Set the local Maven repository, this were dependencies are downloaded to. 
* **remote_repo( url )**: Add additional url of remote Maven repository.
* **group( groups )**: Set the group for nested jar or pom. A single or Array of groups can be set.
* **jar( notations, opts = {} )**: Add Jar dependency in artifact notation, artifact:group:version as the bare minimum. A single or Array of notations can be passed. Default group is _default_, can be specified by setting _opts = { :group => ['group_name'] }_
* **pom( pom_path, opts = {} )**: Add a local Maven pom, default is to load dependencies for `runtime` and `compile` scopes. To select the scopes to be loaded from the pom, set the _opts = { :scopes => ['test'] }_

#### Example Jarfile

    repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
  	
    // Default group is default
    jar "org.apache.mina:mina-core:2.0.4"
  
    group 'runtime' do
      jar 'org.apache.tomcat:servlet-api:jar:6.0.35'
    end
  
    group 'test' do
      jar 'junit:junit:jar:4.10', :group => 'test'
    end
	
### Resolving dependencies

**LockJar.lock( *args )**: Using a Jarfile, creates a lock file. Depending on the type of arg, a different configuration is set.
* _[String]_ will set the Jarfile path, e.g. `'/somewhere/Jarfile.different'`. Default jarfile is `'Jarfile'`
* _[Hash]_ will set the options, e.g. `{ :local_repo => 'path' }`
  * **:download** _[Boolean]_ if true, will download jars to local repo. Defaults to true.
  * **:local_repo** _[String]_ sets the local repo path. Defaults to `ENV['M2_REPO']` or `'~/.m2/repository'`
  * **:lockfile** _[String]_ sets the Jarfile.lock path. Default lockfile is `'Jarfile.lock'`.

When the Jarfile is locked, the transitive dependencies are resolved and saved to the Jarfile.lock file.

Example of locking a Jarfile to a Jarfile.lock

    LockJar.lock
  
 
### Jarfile.lock

The _Jarfile.lock_ generated is a YAML file containing information on how to handle the classpath for grouped dependencies and their nested transitive dependencies.

#### The Jarfile.lock
    
    ---
    version: 0.7.0
    groups:
      default:
        dependencies:
        - ch.qos.logback:logback-classic:jar:0.9.24
        - ch.qos.logback:logback-core:jar:0.9.24
        - com.metapossum:metapossum-scanner:jar:1.0
        - com.slackworks:modelcitizen:jar:0.2.2
        - commons-beanutils:commons-beanutils:jar:1.8.3
        - commons-io:commons-io:jar:1.4
        - commons-lang:commons-lang:jar:2.6
        - commons-logging:commons-logging:jar:1.1.1
        - junit:junit:jar:4.7
        - org.apache.mina:mina-core:jar:2.0.4
        - org.slf4j:slf4j-api:jar:1.6.1
        artifacts:
        - jar:org.apache.mina:mina-core:jar:2.0.4:
            transitive:
              org.slf4j:slf4j-api:jar:1.6.1: {}
        - pom:spec/pom.xml:
            scopes:
            - runtime
            - compile
            transitive:
              com.metapossum:metapossum-scanner:jar:1.0:
                junit:junit:jar:4.7: {}
                commons-io:commons-io:jar:1.4: {}
              commons-beanutils:commons-beanutils:jar:1.8.3:
                commons-logging:commons-logging:jar:1.1.1: {}
              ch.qos.logback:logback-classic:jar:0.9.24:
                ch.qos.logback:logback-core:jar:0.9.24: {}
              commons-lang:commons-lang:jar:2.6: {}
      development:
        dependencies:
        - com.typesafe:config:jar:0.5.0
        artifacts:
        - jar:com.typesafe:config:jar:0.5.0:
            transitive: {}
      test:
        dependencies:
        - junit:junit:jar:4.10
        - org.hamcrest:hamcrest-core:jar:1.1
        artifacts:
        - jar:junit:junit:jar:4.10:
            transitive:
              org.hamcrest:hamcrest-core:jar:1.1: {}
    ...

  
  
### Accessing Jars
**LockJar.install(*args)**: Download Jars in the Jarfile.lock
* _[String]_ will set the Jarfile.lock path, e.g. `'Better.lock'`. Default lock file is `'Jarfile.lock'`.
* _[Array<String>]_ will set the groups, e.g. `['compile','test']`. Defaults group is _default_.
* _[Hash]_ will set the options, e.g. `{ :local_repo => 'path' }`
  * **:local_repo** _[String]_ sets the local repo path. Defaults to `ENV['M2_REPO']` or `'~/.m2/repository'`
  
**LockJar.list(*args)**: Lists all dependencies as notations for groups from the Jarfile.lock.  Depending on the type of arg, a different configuration is set.  
* _[String]_ will set the Jarfile.lock path, e.g. `'Better.lock'`. Default lock file is `'Jarfile.lock'`.
* _[Array<String>]_ will set the groups, e.g. `['default', 'runtime']`. Defaults group is _default_.
* _[Hash]_ will set the options, e.g. `{ :local_repo => 'path' }`
  * **:local_repo** _[String]_ sets the local repo path. Defaults to `ENV['M2_REPO']` or `'~/.m2/repository'`
  * **:local_paths** _[Boolean]_ converts the notations to paths of jars in the local repo
  * **:resolve** _[Boolean]_ to true will make transitive dependences resolve before returning list of jars
  
**LockJar.load(*args)**: Loads all dependencies to the classpath for groups from the Jarfile.lock. Default group is _default_. Default lock file is _Jarfile.lock_.
* _[String]_ will set the Jarfile.lock, e.g. `'Better.lock'`
* _[Array<String>]_ will set the groups, e.g. `['default', 'runtime']`
* _[Hash]_ will set the options, e.g. `{ :local_repo => 'path' }`
  * **:local_repo** _[String]_ sets the local repo path
  * **:resolve** _[Boolean]_ to true will make transitive dependences resolve before loading to classpath 

Once a _Jarfile.lock_ is generated, you can list all resolved jars by
  
    jars = LockJar.list
  
or directly load all Jars into the classpath
  
    jars = LockJar.load  

Do not forget, if you change your _Jarfile_, you have to re-generate the _Jarfile.lock_.
  
See also [loading Jars into a custom ClassLoader](https://github.com/mguymon/lock_jar/wiki/ClassLoader).

### Shortcuts

#### Skipping the Jarfile

You can skip the _Jarfile_ and _Jarfile.lock_ to directly play with dependencies by passing a block to _LockJar.lock_, _LockJar.list_, and _LockJar.load_

#### Lock without a Jarfile

    LockJar.lock do
      jar 'org.eclipse.jetty:example-jetty-embedded:jar:8.1.2.v20120308'
    end

#### List without a Jarfile.lock
    
    LockJar.list do
      jar 'org.eclipse.jetty:example-jetty-embedded:jar:8.1.2.v20120308'
    end

#### Load without a Jarfile.lock
    
    LockJar.load do
      jar 'org.eclipse.jetty:example-jetty-embedded:jar:8.1.2.v20120308'
    end

Since you skipped the locking part, mostly likely you will need to resolve the dependences in the block, just pass the _:resolve => true_ option to enable dependency resolution (also works for _LockJar.list_).

    LockJar.load( :resolve => true ) do
      jar 'org.eclipse.jetty:example-jetty-embedded:jar:8.1.2.v20120308'
    end

## Command line

There is a simple command line helper. You can lock a _Jarfile_ with the following command

    lockjar lock

List jars in a _Jarfile.lock_ with 
 
    lockjar list
  
Download all jars in a _Jarfile.lock_ with

    lockjar install
  
_lockjar_ _--help_ will give you list of all commands and their options.

## Gem Integration

### Installing Jars with a Gem

LockJar can be triggered when a Gem is installed by using a [Gem extension](http://docs.rubygems.org/read/chapter/20#extensions)
of type _Rakefile_. The cavaet is the task to install the jars must be the default for the Rakefile.

A Gem spec with _Rakefile_ extension:

    Gem::Specification.new do |s|
      s.extensions = ["Rakefile"]
    end

Rakefile with default to install Jars using LockJar:

    task :default => :prepare

    task :prepare do
      require 'lock_jar'
      
      # get jarfile relative the gem dir
      lockfile = File.expand_path( "../Jarfile.lock", __FILE__ ) 
      
      LockJar.install( :lockfile => lockfile )
    end
    
#### Work around for Rakefile default

The downside of using the Gem extension Rakefile is it requires the default to 
point at the task to download the jars (from the example Rakefile, 
`task :default => :prepare`). To get around this, I used a Rakefile called 
_PostInstallRakefile_ to handle the `task :prepare`. When packaging the gem, _PostInstallRakefile_ is
renamed to `Rakefile`.

### Manually installing Jars

Instead of rely in a Rakefile to install Jars when the Gem is installed, Jars can be manually installed. The following
Ruby needs to be called before calling `LockJar.load`. Only Jars that are missing are downloaded.

      #get jarfile relative the gem dir
      lockfile = File.expand_path( "../Jarfile.lock", __FILE__ ) 
      
      # Download any missing Jars
      LockJar.install( lockfile )

### Loading

With the Jars installed, loading the classpath for the Gem is simple. 
As part of the load process for the Gem (an entry file that is required, etc) use the following:

      #get jarfile relative the gem dir
      lockfile = File.expand_path( "../Jarfile.lock", __FILE__ ) 
      
      # Loads the ClassPath with Jars from the lockfile
      LockJar.load( :lockfile => lockfile )

See also [loading Jars into a custom ClassLoader](https://github.com/mguymon/lock_jar/wiki/ClassLoader).

## Buildr Integration

LockJar integrates with [Buildr](http://buildr.apache.org/) using an [Addon](https://github.com/mguymon/lock_jar/blob/master/lib/lock_jar/buildr.rb). This allows the Jarfile to be defined directly into a _buildfile_. A global LockJar definition can be set and is inherited to all projects. Each project may have its own LockJar definition. A lock file is generated per project based on the project name.

A new Buildr task is added to generate the lockfile for all projects

    buildr lock_jar:lock
  
and a task per project to generate the lockfile for a single project

    buildr <app>:<project>:lock_jar:lock

In a project, you can access an Array of notations using the **lock_jars** method, accepts same parameters as [LockJar.list](https://github.com/mguymon/lock_jar#accessing-jars)

    lock_jars()


The _default_ group dependencies are automatically added to the classpath for compiling. The _test_ group dependencies are automatically added to the classpath for tests. Do not forget, if you change the LockJar definitions, you have to rerun the **lock_jar:lock** task.


### Example

Sample buildfile with LockJar

    require 'lock_jar/buildr'
    
    # app definition, inherited into all projects
    lock_jar do

         group 'test' do
           jar 'junit:junit:jar:4.10'
         end
    end

    define 'app' do

       def 'project1' do
         lock_jar do
           jar  "org.apache.mina:mina-core:2.0.4"
         end
       end

       def 'project2' do
          lock_jar do
            pom 'pom.xml'
          end
       end

    end

Generated the following lock files using **lock_jar:lock**

* _project1.lock_ - contains _junit_ and _mina_ jars.
* _project2.lock_ - contains _junit_ and _pom.xml_ jars.
  
## Bundler Integration

Bundler integration is **experimental** right now. [LockJar patches Bundler](https://github.com/mguymon/lock_jar/blob/master/lib/lock_jar/bundler.rb) 
to allow creation of a _Jarfile.lock_ when Bundler calls `install` and `update`. The dependencies from the _Jarfile.lock_ are automatically loaded when
Bundler  calls `setup` and `require`. To enable this support, add this require to your _Gemfile_

    require 'lock_jar/bundler'

You can optionally create a _Jarfile_ that will automatically be included when you `bundle install` or `bundle update`. Otherwise
Gems with a Jarfile will be merge to generate a _Jarfile.lock_. The Jarfile.lock will be loaded when Bundler calls `setup` or `require`.

### Bundler to LockJar groups

LockJar will merge the dependencies from the `default` and `runtime` group of a Gem's _Jarfile_. These will be placed in the 
lockfile under Gem's corresponding Bundler group. For example, the following Gemfile:

    group :development do
      gem 'solr_sail', '~>0.1.0'
    end

Would produce the follow _Jarfile.lock_ excerpt:

    ---
    version: 0.7.0
    merged:
    - gem:solr_sail:gems/solr_sail-0.1.0-java/Jarfile
    groups:
      default:
        dependencies: []
        artifacts: []
      development:
        dependencies:
         - ch.qos.logback:logback-classic:jar:1.0.6
         - ch.qos.logback:logback-core:jar:1.0.6
         - com.google.guava:guava:jar:r05

Since `solr_sail` is defined in the _Gemfile's_ `development` group, the corresponding _Jarfile.lock_ dependencies are also under the `development` group.
      
## License

Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with this
work for additional information regarding copyright ownership.  The ASF
licenses this file to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
License for the specific language governing permissions and limitations under
the License.

