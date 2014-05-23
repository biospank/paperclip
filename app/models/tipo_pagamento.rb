# encoding: utf-8

module Models
  class TipoPagamento < ActiveRecord::Base
    include Base::Model

    IN_ATTESA = [6, 12]

    set_table_name :tipi_pagamento
    belongs_to :categoria
    belongs_to :banca, :foreign_key => 'banca_id'
    belongs_to :pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'pdc_dare_id'
    belongs_to :pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'pdc_avere_id'
    belongs_to :nc_pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'nc_pdc_dare_id'
    belongs_to :nc_pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'nc_pdc_avere_id'

    validates_presence_of :codice,
      :message => "Inserire il codice"

    validates_presence_of :descrizione,
      :message => "Inserire la descrizione"

    def valido?
      if configatron.bilancio.attivo
        unless IN_ATTESA.include? self.id
          return ((self.pdc_dare || self.pdc_avere) && (self.nc_pdc_dare || self.nc_pdc_avere))
        end
      else
        unless IN_ATTESA.include? self.id
          return (cassa_dare? || cassa_avere? || banca_dare? || banca_avere? || fuori_partita_dare? || fuori_partita_avere?) &&
            (nc_cassa_dare? || nc_cassa_avere? || nc_banca_dare? || nc_banca_avere? || nc_fuori_partita_dare? || nc_fuori_partita_avere?)
        end
      end
      return true
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

    def movimento_di_banca_dare?(nota_di_credito=false)
      if(nota_di_credito)
        nc_banca_dare?
      else
        banca_dare?
      end
    end

    def movimento_di_banca_avere?(nota_di_credito=false)
      if(nota_di_credito)
        nc_banca_avere?
      else
        banca_avere?
      end
    end

    def conto_incompleto?
      !self.valido?
    end

    protected

    def validate()
      if configatron.bilancio.attivo
        errors.add(:pdc_dare, "Inserire almeno un conto in 'Scritture PD Fattura' e 'Scritture PD Nota di credito'") unless self.valido?
      else
        errors.add(:pdc_dare, "Valorizzare almeno un flag in 'Opzioni Fattura' e 'Opzioni Nota di credito'") unless self.valido?
        if(self.banca and
           ((self.banca_dare == 0 and self.banca_avere == 0) or
            (self.nc_banca_dare == 0 and self.nc_banca_avere == 0)))
          errors.add(:banca, "Le opzioni Fattura/Nota di credito devono essere compatibili con la banca selezionata.")
        end
      end
    end

  end

end
