# encoding: utf-8

module Models
  class Movimento < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    CARICO = 'Carico'
    SCARICO = 'Scarico'

    set_table_name :movimenti
    belongs_to :prodotto
    belongs_to :magazzino
    belongs_to :riga_ordine
    belongs_to :riga_fattura, :class_name => "Models::RigaFatturaCliente", :foreign_key => 'riga_fattura_id'

    def calcola_imponibile
      if self.prodotto.aliquota
        self.imponibile = (self.prezzo_vendita * 100 / (self.prodotto.aliquota.percentuale + 100))
      else
        self.imponibile = self.prezzo_vendita
      end
    end

    def calcola_totale
      if self.prodotto.aliquota
        self.prezzo_vendita = (self.imponibile + (self.imponibile * self.prodotto.aliquota.percentuale / 100))
      else
        self.prezzo_vendita = self.imponibile
      end
    end

    protected

    def validate
      if(qta_non_valida?)
        errors.add(:qta, "Quantità deve essere maggiore di 0")
      end
    end

    def qta_non_valida?
     (self.qta.nil? || self.qta <=0)
    end

    def qta_eccedente?
      # controllo sulla quantita scaricata
     ((self.new_record?) && (!self.qta.nil?) && (self.qta > self.prodotto.residuo))
    end

  end
end
