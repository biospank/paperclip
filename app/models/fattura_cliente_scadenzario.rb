# encoding: utf-8

module Models
  class FatturaClienteScadenzario < FatturaCliente
    
    attr_accessor :totale_incassi
    
    has_many :pagamento_fattura_cliente, :class_name => 'Models::PagamentoFatturaCliente', :foreign_key => 'fattura_cliente_id', :dependent => :delete_all, :order => 'pagamenti_fatture_clienti.id'
    has_many :righe_fattura_pdc, :class_name => 'Models::RigaFatturaPdc', :foreign_key => 'fattura_cliente_id', :dependent => :delete_all, :order => 'righe_fattura_pdc.id'

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
      end
    end
  end
end