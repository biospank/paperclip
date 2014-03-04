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
    belongs_to :nc_pdc_dare, :class_name => "Models::Pdc", :foreign_key => 'nc_pdc_dare_id'
    belongs_to :nc_pdc_avere, :class_name => "Models::Pdc", :foreign_key => 'nc_pdc_avere_id'

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
      self.valido? && self.pdc_dare.nil? && self.pdc_avere.nil? && self.nc_pdc_dare.nil? && self.nc_pdc_avere.nil?
    end

    protected
    
    def validate()
      if configatron.bilancio.attivo
        # se il conto fattura in dare dell'incasso/pagamento ha una banca associata
        # ma non e' un incasso/pagamento che movimenta la banca in dare
        if((self.pdc_dare && self.pdc_dare.banca) &&
            (!self.movimento_di_banca_dare?))
          errors.add(:pdc_dare, "Il conto fattura in dare ha una banca associata ma l'opzione fattura banca in dare non è selezionata.")
        end

        # se il conto fattura in avere dell'incasso/pagamento ha una banca associata
        # ma non e' un incasso/pagamento che movimenta la banca in avere
        if((self.pdc_avere && self.pdc_avere.banca) &&
            (!self.movimento_di_banca_avere?))
          errors.add(:pdc_avere, "Il conto fattura in avere ha una banca associata ma l'opzione fattura banca in avere non è selezionata.")
        end

        # se il conto fattura in dare dell'incasso/pagamento non ha una banca associata
        # ma e' un incasso/pagamento che movimenta la banca in dare
        if((!self.pdc_dare.nil? && self.pdc_dare.banca.nil?) &&
            (self.movimento_di_banca_dare?))
          errors.add(:pdc_dare, "Opzione fattura banca dare selezionata:\nil conto fattura in dare deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'.")
        end

        # se il conto fattura in avere dell'incasso/pagamento non ha una banca associata
        # ma e' un incasso/pagamento che movimenta la banca in avere
        if((!self.pdc_avere.nil? && self.pdc_avere.banca.nil?) &&
            (self.movimento_di_banca_avere?))
          errors.add(:pdc_avere, "Opzione fattura banca avere selezionata:\nil conto fattura in 'avere' deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'.")
        end

        # se il conto nota di credito in dare dell'incasso/pagamento ha una banca associata
        # ma non e' un incasso/pagamento che movimenta la banca in dare
        if((self.nc_pdc_dare && self.nc_pdc_dare.banca) &&
            (!self.movimento_di_banca_dare?(true)))
          errors.add(:nc_pdc_dare, "Il conto nota di credito in dare ha una banca associata ma l'opzione nota di credito banca in dare non è selezionata.")
        end

        # se il conto nota di credito in avere dell'incasso/pagamento ha una banca associata
        # ma non e' un incasso/pagamento che movimenta la banca in avere
        if((self.nc_pdc_avere && self.nc_pdc_avere.banca) &&
            (!self.movimento_di_banca_avere?(true)))
          errors.add(:nc_pdc_avere, "Il conto nota di credito in avere ha una banca associata ma l'opzione nota di credito banca in avere non è selezionata.")
        end

        # se il conto nota di credito in dare dell'incasso/pagamento non ha una banca associata
        # ma e' un incasso/pagamento che movimenta la banca in dare
        if((!self.nc_pdc_dare.nil? && self.nc_pdc_dare.banca.nil?) &&
            (self.movimento_di_banca_dare?(true)))
          errors.add(:nc_pdc_dare, "Opzione nota di credito banca dare selezionata:\nil conto nota di credito in dare deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'.")
        end

        # se il conto nota di credito in avere dell'incasso/pagamento non ha una banca associata
        # ma e' un incasso/pagamento che movimenta la banca in avere
        if((!self.nc_pdc_avere.nil? && self.nc_pdc_avere.banca.nil?) &&
            (self.movimento_di_banca_avere?(true)))
          errors.add(:nc_pdc_avere, "Opzione nota di credito banca avere selezionata:\nil conto nota di credito in 'avere' deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'.")
        end

      else
        if(self.banca and
           ((self.banca_dare == 0 and self.banca_avere == 0) or
            (self.nc_banca_dare == 0 and self.nc_banca_avere == 0)))
          errors.add(:banca, "Le opzioni Fattura/Nota di credito devono essere compatibili con la banca selezionata.")
        end
      end
    end
    
  end
  
end