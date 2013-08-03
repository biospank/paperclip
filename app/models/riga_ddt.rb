# encoding: utf-8

module Models
  class RigaDdt < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model
    
    set_table_name :righe_ddt
    belongs_to :ddt, :foreign_key => 'ddt_id'
    
    validates_numericality_of :qta,
      :greater_than => 0,
      :message => "La quantità deve essere maggiore di 0"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    def before_validation_on_create()
      self.qta ||= 0
    end
  
  end
end