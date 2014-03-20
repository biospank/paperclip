# encoding: utf-8

module Models
  class FatturaClienteScadenzario < FatturaCliente
    
    attr_accessor :totale_incassi
    
    has_many :pagamento_fattura_cliente, :class_name => 'Models::PagamentoFatturaCliente', :foreign_key => 'fattura_cliente_id', :dependent => :destroy, :order => 'pagamenti_fatture_clienti.id'
    has_many :righe_fattura_pdc, :class_name => 'Models::RigaFatturaPdc', :foreign_key => 'fattura_cliente_id', :dependent => :destroy, :order => 'righe_fattura_pdc.id'
    has_one  :dettaglio_fattura_partita_doppia, :class_name => 'Models::DettaglioFatturaPartitaDoppia', :foreign_key => 'fattura_cliente_id', :dependent => :destroy
    has_one  :scrittura_pd, :through => :dettaglio_fattura_partita_doppia, :source => :scrittura # riferimento all'associazione :scrittura di :dettaglio_fattura_partita_doppia

    validates_exclusion_of :importo,
      :in => [0],
      :message => "L'importo della fattura deve essere diverso da 0."

    def before_save
      self.azienda = Azienda.current
      self.da_scadenzario = true
      # DA VERIFICARE
      unless da_fatturazione?
        self.imponibile = 0.0
        self.iva = 0.0
      end
    end
    
    protected
    
    def validate()
      if errors.empty? 
        if self.new_record?
          if numero_duplicato?
            errors.add(:num, "Numero fattura o nota di credito già utilizzato.")
          end  
        end
        logger.debug("Importo fattura: " + Helpers::ApplicationHelper.currency(self.importo))
        logger.debug("Totale pagamenti: " + Helpers::ApplicationHelper.currency(self.totale_incassi))
        if Helpers::ApplicationHelper.currency(self.importo) != Helpers::ApplicationHelper.currency(self.totale_incassi)
          logger.debug("Importo fattura: " + sprintf("%8.20f", self.importo))
          logger.debug("Totale pagamenti: " + sprintf("%8.20f", self.totale_incassi))
          errors.add(:importo, "L'importo della fattura non corrisponde al totale degli incassi.")
        end

        errors.add(:data_emissione, "La data di emissione non può essere maggiore della data odierna.") if self.data_emissione.future?

      end
    end
  end
end