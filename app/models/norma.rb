# encoding: utf-8

module Models
  class Norma < ActiveRecord::Base
    include Base::Model

    set_table_name :norma

    validates_presence_of :codice, 
      :message => "Inserire il codice"

    validates_presence_of :percentuale, 
      :message => "Inserire la percentuale"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice, 
      :message => "Codice norma gia' utilizzato."
    
    def modificabile?
      num = Models::RigaFatturaPdc.count(:conditions => ["norma_id = ?", self.id])
      num == 0
    end
  
  end
end