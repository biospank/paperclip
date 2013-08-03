# encoding: utf-8

module Models
  class IdentModel < Array
    def initialize(id=nil, type=nil)
      @id = id
      @type = type
    end
    
    def ident()
      {:id => @id, :type => @type}
    end
  end
end