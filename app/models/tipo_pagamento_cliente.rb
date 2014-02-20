# encoding: utf-8

module Models
  class TipoPagamentoCliente < TipoPagamento

    # se non trova nulla ritorna un array vuoto
    named_scope :by_codice, lambda { |codice|
      { :conditions => {:categoria_id => Helpers::AnagraficaHelper::CLIENTI, :codice => codice } }
    }

    before_save do |tipo_pagamento| 
      TipoPagamento.update_all('predefinito = 0', ['categoria_id = ? ', Helpers::AnagraficaHelper::CLIENTI]) if tipo_pagamento.predefinito? 
    end
    
    def before_validation_on_create()
      self.categoria_id = Helpers::AnagraficaHelper::CLIENTI
    end
    
    validates_uniqueness_of :codice, 
      :scope => :categoria_id,
      :message => "Codice modalità incasso gia' utilizzato."

    # pdc_dare è obbligatorio se è attivo il bilancio e se valorizzato il flag in dare delle opzioni fattura
    validates_presence_of :pdc_dare,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) && (incasso.cassa_dare? ||
              incasso.banca_dare? ||
              incasso.fuori_partita_dare?))
      },
      :message => "L'incasso prevede un conto fattura in dare.\nInserire il conto in dare oppure premere F5 per la ricerca."

    # pdc_avere è obbligatorio se è attivo il bilancio e se valorizzato il flag in avere delle opzioni fattura
    validates_presence_of :pdc_avere,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) && (incasso.cassa_avere? ||
              incasso.banca_avere? ||
              incasso.fuori_partita_avere?))
      },
      :message => "L'incasso prevede un conto fattura in avere.\nInserire il conto in avere oppure premere F5 per la ricerca."

    # nc_pdc_dare è obbligatorio se è attivo il bilancio e se valorizzato il flag in dare delle opzioni nota di credito
    validates_presence_of :nc_pdc_dare,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) && (incasso.nc_cassa_dare? ||
              incasso.nc_banca_dare? ||
              incasso.nc_fuori_partita_dare?))
      },
      :message => "L'incasso prevede un conto nota di credito in dare.\nInserire il conto in dare oppure premere F5 per la ricerca."

    # nc_pdc_avere è obbligatorio se è attivo il bilancio e se valorizzato il flag in avere delle opzioni nota di credito
    validates_presence_of :nc_pdc_avere,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) && (incasso.nc_cassa_avere? ||
              incasso.nc_banca_avere? ||
              incasso.nc_fuori_partita_avere?))
      },
      :message => "L'incasso prevede un conto nota di credito in avere.\nInserire il conto in avere oppure premere F5 per la ricerca."

    # se il conto fattura in dare dell'incasso ha una banca associata
    # ma non e' un incasso che movimenta la banca in dare
    validates_presence_of :pdc_dare,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (incasso.pdc_dare && incasso.pdc_dare.banca) &&
          (!incasso.movimento_di_banca_dare?))
      },
      :message => "Il conto fattura in dare ha una banca associata ma l'opzione fattura banca in dare non è selezionata."

    # se il conto fattura in avere dell'incasso ha una banca associata
    # ma non e' un incasso che movimenta la banca in avere
    validates_presence_of :pdc_avere,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (incasso.pdc_avere && incasso.pdc_avere.banca) &&
          (!incasso.movimento_di_banca_avere?))
      },
      :message => "Il conto fattura in avere ha una banca associata ma l'opzione fattura banca in avere non è selezionata."

    # se il conto fattura in dare dell'incasso non ha una banca associata
    # ma e' un incasso che movimenta la banca in dare
    validates_presence_of :pdc_dare,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (!incasso.pdc_dare && !incasso.pdc_dare.banca) &&
          (incasso.movimento_di_banca_dare?))
      },
      :message => "Opzione fattura banca dare selezionata:\nil conto fattura in dare deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'."

    # se il conto fattura in avere dell'incasso non ha una banca associata
    # ma e' un incasso che movimenta la banca in avere
    validates_presence_of :pdc_avere,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (!incasso.pdc_avere && !incasso.pdc_avere.banca) &&
          (incasso.movimento_di_banca_avere?))
      },
      :message => "Opzione fattura banca avere selezionata:\nil conto fattura in 'avere' deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'."

    # se il conto nota di credito in dare dell'incasso ha una banca associata
    # ma non e' un incasso che movimenta la banca in dare
    validates_presence_of :nc_pdc_dare,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (incasso.nc_pdc_dare && incasso.nc_pdc_dare.banca) &&
          (!incasso.movimento_di_banca_dare?(true)))
      },
      :message => "Il conto nota di credito in dare ha una banca associata ma l'opzione nota di credito banca in dare non è selezionata."

    # se il conto nota di credito in avere dell'incasso ha una banca associata
    # ma non e' un incasso che movimenta la banca in avere
    validates_presence_of :nc_pdc_avere,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (incasso.nc_pdc_avere && incasso.nc_pdc_avere.banca) &&
          (!incasso.movimento_di_banca_avere?(true)))
      },
      :message => "Il conto nota di credito in avere ha una banca associata ma l'opzione nota di credito banca in avere non è selezionata."

    # se il conto nota di credito in dare dell'incasso non ha una banca associata
    # ma e' un incasso che movimenta la banca in dare
    validates_presence_of :nc_pdc_dare,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (!incasso.nc_pdc_dare && !incasso.nc_pdc_dare.banca) &&
          (incasso.movimento_di_banca_dare?(true)))
      },
      :message => "Opzione nota di credito banca dare selezionata:\nil conto nota di credito in dare deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'."

    # se il conto nota di credito in avere dell'incasso non ha una banca associata
    # ma e' un incasso che movimenta la banca in avere
    validates_presence_of :nc_pdc_avere,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) &&
            (!incasso.nc_pdc_avere && !incasso.nc_pdc_avere.banca) &&
          (incasso.movimento_di_banca_avere?(true)))
      },
      :message => "Opzione nota di credito banca avere selezionata:\nil conto nota di credito in 'avere' deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'."

   def modificabile?
      num = 0
      num = Models::PagamentoFatturaCliente.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num += Models::MaxiPagamentoCliente.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num == 0
    end
  
  end

end