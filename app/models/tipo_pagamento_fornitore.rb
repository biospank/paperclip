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


    # # pdc_dare è obbligatorio se è attivo il bilancio e se valorizzato il flag in dare delle opzioni fattura
    # validates_presence_of :pdc_dare,
    #   :if => Proc.new { |pagamento|
    #     ((configatron.bilancio.attivo) && (pagamento.cassa_dare? ||
    #           pagamento.banca_dare? ||
    #           pagamento.fuori_partita_dare?))
    #   },
    #   :message => "Il pagamento prevede un conto fattura in dare.\nInserire il conto in dare oppure premere F5 per la ricerca."
    #
    # # pdc_avere è obbligatorio se è attivo il bilancio e se valorizzato il flag in avere delle opzioni fattura
    # validates_presence_of :pdc_avere,
    #   :if => Proc.new { |pagamento|
    #     ((configatron.bilancio.attivo) && (pagamento.cassa_avere? ||
    #           pagamento.banca_avere? ||
    #           pagamento.fuori_partita_avere?))
    #   },
    #   :message => "Il pagamento prevede un conto fattura in avere.\nInserire il conto in avere oppure premere F5 per la ricerca."
    #
    # # nc_pdc_dare è obbligatorio se è attivo il bilancio e se valorizzato il flag in dare delle opzioni nota di credito
    # validates_presence_of :nc_pdc_dare,
    #   :if => Proc.new { |pagamento|
    #     ((configatron.bilancio.attivo) && (pagamento.nc_cassa_dare? ||
    #           pagamento.nc_banca_dare? ||
    #           pagamento.nc_fuori_partita_dare?))
    #   },
    #   :message => "Il pagamento prevede un conto nota di credito in dare.\nInserire il conto in dare oppure premere F5 per la ricerca."
    #
    # # nc_pdc_avere è obbligatorio se è attivo il bilancio e se valorizzato il flag in avere delle opzioni nota di credito
    # validates_presence_of :nc_pdc_avere,
    #   :if => Proc.new { |pagamento|
    #     ((configatron.bilancio.attivo) && (pagamento.nc_cassa_avere? ||
    #           pagamento.nc_banca_avere? ||
    #           pagamento.nc_fuori_partita_avere?))
    #   },
    #   :message => "Il pagamento prevede un conto nota di credito in avere.\nInserire il conto in avere oppure premere F5 per la ricerca."

    def modificabile?
      num = 0
      num = Models::PagamentoFatturaFornitore.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num += Models::MaxiPagamentoFornitore.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num == 0
    end

  end
end
