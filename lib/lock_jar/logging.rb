require 'naether/java'

module LockJar
  #
  class Logging
    def self.verbose!
      Naether::Java.exec_static_method(
        'com.tobedevoured.naether.LogUtil',
        'setDefaultLogLevel',
        ['info']
      )
    end
  end
end
