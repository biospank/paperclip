# encoding: utf-8

module Models
  class TipoPagamentoFornitore < TipoPagamento

    # se non trova nulla ritorna un array vuoto
    named_scope :by_codice, lambda { |codice|
      { :conditions => {:categoria_id => Helpers::AnagraficaHelper::FORNITORI, :codice => codice } }
    }

    before_save do |tipo_pagamento| 
      TipoPagamento.update_all('predefinito = 0', ['categoria_id = ? ', Helpers::AnagraficaHelper::FORNITORI]) if tipo_pagamento.predefinito? 
    end
    
    def before_validation_on_create()
      self.categoria_id = Helpers::AnagraficaHelper::FORNITORI
    end
    
    validates_uniqueness_of :codice, 
      :scope => :categoria_id,
      :message => "Codice modalità pagamento gia' utilizzato."

    
    # pdc_dare è obbligatorio se è attivo il bilancio e se valorizzato il flag in dare
    validates_presence_of :pdc_dare,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) && (incasso.cassa_dare? ||
              incasso.banca_dare? ||
              incasso.fuori_partita_dare? ||
              incasso.ns_cassa_dare? ||
              incasso.ns_banca_dare? ||
              incasso.ns_fuori_partita_dare?))
      },
      :message => "Il pagamento prevede un conto in dare.\nInserire il conto in dare oppure premere F5 per la ricerca."

    # pdc_avere è obbligatorio se è attivo il bilancio e se valorizzato il flag in avere
    validates_presence_of :pdc_avere,
      :if => Proc.new { |incasso|
        ((configatron.bilancio.attivo) && (incasso.cassa_avere? ||
              incasso.banca_avere? ||
              incasso.fuori_partita_avere? ||
              incasso.ns_cassa_avere? ||
              incasso.ns_banca_avere? ||
              incasso.ns_fuori_partita_avere?))
      },
      :message => "Il pagamento prevede un conto in avere.\nInserire il conto in avere oppure premere F5 per la ricerca."

    def modificabile?
      num = 0
      num = Models::PagamentoFatturaFornitore.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num += Models::MaxiPagamentoFornitore.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num == 0
    end
  
  end
end