# encoding: utf-8

require 'app/models/base'

module Models
  class Causale < ActiveRecord::Base
    include Base::Model

    set_table_name :causali

    belongs_to :banca, :foreign_key => 'banca_id'

    before_save do |causale| 
      Causale.update_all('predefinita = 0') if causale.predefinita? 
    end
    
    validates_presence_of :codice, 
      :message => "Inserire il codice"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice, 
      :message => "Codice causale gia' utilizzato."

    def modificabile?
      num = 0
      num = Models::Scrittura.count(:conditions => ["causale_id = ?", self.id]) unless self.id.nil?
      num == 0
    end

    def movimento_di_banca?()
      return banca_dare? || banca_avere?
    end
    
    protected
    
    def validate()
      if(self.banca and self.banca_dare == 0 and self.banca_avere == 0)
        errors.add(:banca, "Le opzioni non sono compatibili con la banca selezionata.")
      end
    end
    
  end
end