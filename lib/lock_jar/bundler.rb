module LockJar
  
  module Bundler
    
  end
  
end

module Bundler
  class Definition
    alias :_lockjar_replaced_to_lock :to_lock
    def to_lock
      _lockjar_replaced_to_lock
   
      puts "---"
      definition = Bundler.definition
      # lockjar  | bundler
      # ------------------
      # runtime  | default 
      #          | asset
      # compile  | development + default
      # test     | test + development + default
      # provided | ? 
      #          |  a custom named group
      
      definition.groups.each do |group|
        puts "!1!! #{group} !!!!"
        puts definition.specs_for( [group] ).inspect
        puts ""
      end
      puts "---"
    end
    
  end
end