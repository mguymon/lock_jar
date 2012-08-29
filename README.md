# LockJar

LockJar manages Java Jars for Ruby. Powered by [Naether](https://github.com/mguymon/naether) to create a frankenstein of Bundler and Maven. A Jarfile ([example](https://github.com/mguymon/lock_jar/blob/master/spec/Jarfile)) is used to generate a Jarfile.lock that contains all the resolved jar dependencies for scopes runtime, compile, and test. The Jarfile.lock can be used to populate the classpath.

LockJar can be used directly or integrates directly with Bundler and Buildr.

https://github.com/mguymon/lock_jar

[RDoc](http://rubydoc.info/github/mguymon/lock_jar/master/frames)

## Install

    gem install lock_jar

## Usage

### Jarfile

A Jarfile is a simple file using a Ruby DSL for defining a project's dependencies using the following 
methods:

* **local( path )**: Set the local Maven repository, this were dependencies are downloaded to. 
* **repository( url )**: Add additional urlr of remote Maven repository.
* **map( notation, paths )**: Map local compiled class paths to a notation. The map is applied when loading or listing jar. This is useful for local development that overrides an artifact. A single or Array of paths can be set.
* **exclude( excludes )**: Add a artifact:group that will be excluded from resolved dependencies. A single or Array of excludes can be set.
* **jar( notations, opts = {} )**: Add Jar dependency in artifact notation, artifact:group:version as the bare minimum. A single or Array of notations can be passed. Default scope is _compile_, can be specified by setting _opts = { :scope => ['new_scope'] }_
* **pom( pom_path, opts = {} )**: Add a local Maven pom, default is to load dependencies for all scopes. To select the scopes to be loaded from the pom, set the _opts = { :scopes => ['new_scope'] }_
* **scope( scopes )**: Set the scope for nested jar or pom. A single or Array of scopes can be set.

#### Example Jarfile

    repository 'http://repository.jboss.org/nexus/content/groups/public-jboss'
  	
    // Default scope is compile
    jar "org.apache.mina:mina-core:2.0.4"
  
    scope 'runtime' do
      jar 'org.apache.tomcat:servlet-api:jar:6.0.35'
    end
  
    scope 'test' do
      jar 'junit:junit:jar:4.10'
    end
  
	
### Resolving dependencies

* **LockJar.lock( *args )**: Using a Jarfile, creates a lock file. Depending on the type of arg, a different configuration is set.
  * An arg of a String will set the Jarfile path, e.g. _'/somewhere/Jarfile.different'_. Default jarfile is _'Jarfile'_
  * An arg of a Hash will set the options, e.g. _{ :local_repo => 'path' }_
      * **:download** if true, will download jars to local repo. Defaults to true.
      * **:local_repo** sets the local repo path
      * **:lockfile** sets the Jarfile.lock path. Default lockfile is _Jarfile.lock_.

When the Jarfile is locked, the transitive dependencies are resolved and saved to the Jarfile.lock file.

Example of locking a Jarfile to a Jarfile.lock

    LockJar.lock
  
 
### Jarfile.lock

The _Jarfile.lock_ generated is a YAML file containing the scoped dependencies, their resolved dependencies, and the additional Maven repositories.

#### The Jarfile.lock

    --- 
    repositories: 
      - http://repository.jboss.org/nexus/content/groups/public-jboss
    scopes: 
      compile: 
        dependencies: 
          - org.apache.mina:mina-core:2.0.4
        resolved_dependencies: 
          - org.apache.mina:mina-core:jar:2.0.4
          - org.slf4j:slf4j-api:jar:1.6.1
          - com.slackworks:modelcitizen:jar:0.2.2
          - commons-lang:commons-lang:jar:2.6
          - commons-beanutils:commons-beanutils:jar:1.8.3
          - commons-logging:commons-logging:jar:1.1.1
          - ch.qos.logback:logback-classic:jar:0.9.24
          - ch.qos.logback:logback-core:jar:0.9.24
          - com.metapossum:metapossum-scanner:jar:1.0
          - commons-io:commons-io:jar:1.4
          - junit:junit:jar:4.7
      runtime: 
        dependencies: 
          - org.apache.tomcat:servlet-api:jar:6.0.35
        resolved_dependencies: 
          - org.apache.tomcat:servlet-api:jar:6.0.35
      test: 
        dependencies: 
          - junit:junit:jar:4.10
        resolved_dependencies: 
          - junit:junit:jar:4.10
          - org.hamcrest:hamcrest-core:jar:1.1
  
  
### Accessing Jars

* **LockJar.list(*args)**: Lists all dependencies as notations for scopes from the Jarfile.lock.  Depending on the type of arg, a different configuration is set.  
  * An arg of a String will set the Jarfile.lock path, e.g. _Better.lock_. Default lock file is _Jarfile.lock_.
  * An arg of an Array will set the scopes, e.g. _['compile','test']_. Defaults scopes are _compile_ and _runtime_.
  * An arg of a Hash will set the options, e.g. _{ :local_repo => 'path' }_
      * **:local_repo** sets the local repo path
      * **:local_paths** converts the notations to paths of jars in the local repo
      * **:resolve** to true will make transitive dependences resolve before returning list of jars
  
* **LockJar.load(*args)**: Loads all dependencies to the classpath for scopes from the Jarfile.lock. Defaults scopes are _compile_ and _runtime_. Default lock file is _Jarfile.lock_.
  * An arg of a String will set the Jarfile.lock, e.g. _'Better.lock'_
  * An arg of an Array will set the scopes, e.g. _['compile','test']_
  * An arg of a Hash will set the options, e.g. _{ :local_repo => 'path' }_
     * **:local_repo** sets the local repo path
     * **:resolve** to true will make transitive dependences resolve before loading to classpath 

Once a _Jarfile.lock_ is generated, you can list all resolved jars by
  
    jars = LockJar.list
  
or directly load all Jars into the classpath
  
    jars = LockJar.load  

Do not forget, if you change your _Jarfile_, you have to re-generate the _Jarfile.lock_.
  
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

## Bundler Integration

Has been deprecated to https://github.com/mguymon/lock_jar/tree/bundler_support
  
## Buildr Integration

LockJar integrates with [Buildr](http://buildr.apache.org/) using an [Addon](https://github.com/mguymon/lock_jar/blob/master/lib/lock_jar/buildr.rb). This allows the Jarfile to be defined directly into a _buildfile_. A global LockJar definition can be set and is inherited to all projects. Each project may have its own LockJar definition. A lock file is generated per project based on the project name.

A new Buildr task is added to generate the lockfile for all projects

    buildr lock_jar:lock
  
and a task per project to generate the lockfile for a single project

    buildr <app>:<project>:lock_jar:lock

In a project, you can access an Array of notations using the **lock_jars** method, accepts same parameters as [LockJar.list](https://github.com/mguymon/lock_jar#accessing-jars)

    lock_jars()


The _compile_ scoped dependencies are automatically added to the classpath for compiling. The test scoped dependencies are automatically added to the classpath for tests. Do not forget, if you change the LockJar definitions, you have to rerun the **lock_jar:lock** task.


### Example

Sample buildfile with LockJar

    require 'lock_jar/buildr'
    
    # app definition, inherited into all projects
    lock_jar do

         scope 'test' do
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

* project1.lock - contains _junit_ and _mina_ jars.
* project2.lock - contains _junit_ and _pom.xml_ jars.
  

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

