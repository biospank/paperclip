# encoding: utf-8

module Models
  class Aliquota < ActiveRecord::Base
    include Base::Model

    set_table_name :aliquote

    before_save do |aliquota| 
      Aliquota.update_all('predefinita = 0') if aliquota.predefinita? 
    end
    
    validates_presence_of :codice, 
      :message => "Inserire il codice"

    validates_presence_of :percentuale, 
      :message => "Inserire la percentuale"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice, 
      :message => "Codice aliquota gia' utilizzato."
    
    def modificabile?
      num = Models::RigaFatturaCliente.count(:conditions => ["aliquota_id = ?", self.id])
      num += Models::RigaNotaSpese.count(:conditions => ["aliquota_id = ?", self.id])
      num == 0
    end
  
  end
end