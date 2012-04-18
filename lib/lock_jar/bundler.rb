require 'rubygems'
require 'bundler/dsl'

module Bundler
  class Dsl
    def jar(notation,opts={})
      unless @jars
        @jars = []
      end
      
      groups = @groups.dup
      opts["group"] = opts.delete("groups") || opts["group"]
      groups.concat Array(opts.delete("group"))
      groups = [:compile] if groups.empty?
      
      @jars << { notation => groups }
    end
    
    def pom(path,opts={})
      unless @poms
        @poms = []
      end
      
      groups = @groups.dup
      opts["group"] = opts.delete("groups") || opts["group"]
      groups.concat Array(opts.delete("group"))
      groups = [:compile] if groups.empty?
      
      @poms << { path => groups }
    end
    
    def to_definition(lockfile, unlock)
      @sources << @rubygems_source unless @sources.include?(@rubygems_source)
      definition = Definition.new(lockfile, @dependencies, @sources, unlock)
      
      if @jars
        definition.jars = @jars
      end
      
      if @poms
        definition.poms = @poms
      end
      
      definition
    end
  end
  
  class Environment
    def jars
      @definition.jars
    end
    
    def poms
      @definition.poms
    end
  end
  
  class Definition
    attr_accessor :jars
    attr_accessor :poms
  end
end