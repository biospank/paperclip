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

   def modificabile?
      num = 0
      num = Models::PagamentoFatturaCliente.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num += Models::MaxiPagamentoCliente.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num == 0
    end
  
  end
end