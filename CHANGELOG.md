## LockJar Changelog

### 0.12.0 (Feburary 23, 2015)

* Add support for `without_default_maven_repo`

### 0.12.2 (Feburary 25, 2015)

* Only write unique set of remote repositories to lockfile

### 0.12.1 (Feburary 25, 2015)

* Fix for writing remote repositories to lockfile

### 0.10.0 (June 27, 2014)

* Extract Bundler out to own Gem - https://github.com/mguymon/lock_jar_bundler

#### 0.10.5 (Feburary 13, 2015)

* Use Naether 0.14.0, with support for NAETHER_MIRROR env

#### 0.10.4 (Feburary 11, 2015)

* Fix bug with excludes in Jarfiles (<a href="https://github.com/mguymon/lock_jar/pull/25">Pull #20</a>) [<a href="https://github.com/pangloss">pangloss</a>]

#### 0.10.3 (Januaray 13, 2015)

* Control the logging of Naether from LockJar::Logging

#### 0.10.2 (November 20, 2014)

* Default to the correct file, based on desired type (<a href="https://github.com/mguymon/lock_jar/pull/22">Pull #20</a>) [<a href="https://github.com/pangloss">pangloss</a>]

#### 0.10.1 (November 19, 2014)

* Use local_repository from Jarfile.lock in install() if none has been passed in (<a href="https://github.com/mguymon/lock_jar/pull/20">Pull #20</a>) [<a href="https://github.com/stewi2">stewi2</a>]
* Add support for merging and locking multiple Jarfiles (<a href="https://github.com/mguymon/lock_jar/pull/21">Pull #21</a>) [<a href="https://github.com/pangloss">pangloss</a>]

### 0.9.0 (March 6, 2014)

* Update to Naether 0.13.1 to fight the chatty log (<a href="https://github.com/mguymon/lock_jar/issues/14">Issue #14</a>)

### 0.8.0 (March 4, 2014)

* Added `local` to DSL for adding local jars (<a href="https://github.com/mguymon/lock_jar/issues/6">Issue #6</a>)

### 0.7.0

* Sort dependences for Jarfile.lock (<a href="https://github.com/mguymon/lock_jar/pull/3">Pull #3</a>) [<a href="https://github.com/chetan">chetan</a>]

#### 0.7.5 (August 23, 2013)

* Update Thor dep, improve specs (<a href="https://github.com/mguymon/lock_jar/pull/10">Pull #10</a>) [<a href="https://github.com/yokolet">yokolet</a>]

#### 0.7.4 (April 17, 2013)

* Fixed Buildr integration (<a href="https://github.com/mguymon/lock_jar/issues/6">Issue #6</a>) [<a href="https://github.com/tobsch">tobsch</a>]
