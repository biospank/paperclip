# encoding: utf-8

module Models
  class Ritenuta < ActiveRecord::Base
    include Base::Model
    
    set_table_name :ritenute

    before_save do |ritenuta| 
      Ritenuta.update_all('predefinita = 0') if ritenuta.predefinita? 
    end
    
    validates_presence_of :codice, 
      :message => "Inserire il codice"

    validates_presence_of :percentuale, 
      :message => "Inserire la percentuale"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice, 
      :message => "Codice ritenuta gia' utilizzato."

    def modificabile?
      num = Models::FatturaCliente.count(:conditions => ["ritenuta_id = ?", self.id])
      num += Models::NotaSpese.count(:conditions => ["ritenuta_id = ?", self.id])
      num == 0
    end

  end
end