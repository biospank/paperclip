# encoding: utf-8

module Helpers
  module BusinessClassHelper
    # mantiene lo stato del record
    attr_accessor :instance_status, :ident#, :original_attributes
  
    # stati del record
    ST_EMPTY = 0
    ST_READ = 1
    ST_INSERT = 2
    ST_UPDATE = 3
    ST_DELETE = 4

    # variabile di classe per identificare gli oggetti che mixano questo modulo
    @@ident_count ||= 0
  
    # inizializzo lo stato
#    def after_find()
#      self.instance_status = ST_READ
#    end
    
    def after_initialize()
      self.instance_status = self.new_record? ? ST_INSERT : ST_READ
    end
    
    # mantiene lo stato degli oggetti
    # nota: deve essere chiamato prima di ogni modifica
    def log_attr(status = ST_UPDATE)
      case instance_status
      when ST_READ
        if status == ST_UPDATE
          @instance_status = ST_UPDATE
        elsif status == ST_DELETE
          @instance_status = ST_DELETE
        end
      when ST_INSERT
        if status == ST_DELETE
          @instance_status = ST_EMPTY
        end
      when ST_UPDATE
        if status == ST_DELETE
          @instance_status = ST_DELETE
        end
      end
      #@original_attributes = attributes.dup if @original_attributes.nil?
      self
    end

    def valid_record?
      ((self.instance_status != BusinessClassHelper::ST_DELETE) && 
          (self.instance_status != BusinessClassHelper::ST_EMPTY))      
    end
    
    def touched?
      ((self.instance_status != ST_READ) && 
          (self.instance_status != ST_EMPTY))      
    end
    
    def ident()
      @ident ||= (@@ident_count += 1)
    end
  
  end
end