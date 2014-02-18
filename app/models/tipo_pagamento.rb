# encoding: utf-8

module Models
  class TipoPagamento < ActiveRecord::Base
    include Base::Model
    
    Modulo = Helpers::ApplicationHelper::Modulo::SCADENZARIO

    set_table_name :tipi_pagamento
    belongs_to :categoria
    belongs_to :banca, :foreign_key => 'banca_id'
    belongs_to :pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'pdc_dare_id'
    belongs_to :pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'pdc_avere_id'

    validates_presence_of :codice, 
      :message => "Inserire il codice"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    def valido?
      cassa_dare? || cassa_avere? || banca_dare? || banca_avere? || fuori_partita_dare? || fuori_partita_avere? ||
      nc_cassa_dare? || nc_cassa_avere? || nc_banca_dare? || nc_banca_avere? || nc_fuori_partita_dare? || nc_fuori_partita_avere?
    end
  
    def movimento_di_banca?(nota_di_credito=false)
      res = false
      if(nota_di_credito)
        res = nc_banca_dare? || nc_banca_avere?
      else
        res = banca_dare? || banca_avere?
      end
      return res
    end

    protected
    
    def validate()
      if(self.banca and 
         ((self.banca_dare == 0 and self.banca_avere == 0) or 
          (self.nc_banca_dare == 0 and self.nc_banca_avere == 0)))
        errors.add(:banca, "Le opzioni Fattura/Nota di credito devono essere compatibili con la banca selezionata.")
      end
    end
    
  end
  
end