# encoding: utf-8

require 'app/models/base'

module Models
  class FatturaFornitore < ActiveRecord::Base
    include Base::Model

    attr_accessor :totale_pagamenti
    
    set_table_name :fatture_fornitori
    belongs_to :fornitore, :foreign_key => 'fornitore_id'
    belongs_to :azienda
    has_many :pagamento_fattura_fornitore, :class_name => 'Models::PagamentoFatturaFornitore', :foreign_key => 'fattura_fornitore_id', :dependent => :delete_all, :order => 'pagamenti_fatture_fornitori.id'
    has_many :righe_fattura_pdc, :class_name => 'Models::RigaFatturaPdc', :foreign_key => 'fattura_fornitore_id', :dependent => :delete_all, :order => 'righe_fattura_pdc.id'
  
    validates_presence_of :data_emissione, 
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :num, 
      :message => "Inserire il numero di fattura o nota di credito."

    validates_exclusion_of :importo,
      :in => [0],
      :message => "L'importo della fattura deve essere diverso da 0."

    def ha_registrazioni_in_prima_nota?
      return PagamentoFatturaFornitore.count(:conditions => ["fattura_fornitore_id = ? and registrato_in_prima_nota = ?", self.id, 1]) > 0
    end
    
    def numero_duplicato?
      self.class.search(:first, :conditions => ["num = ? and #{to_sql_year('data_emissione')} = ? and fornitore_id = ?", num, data_emissione.year.to_s, fornitore.id]) != nil
    end
    
    def before_save
      self.azienda = Azienda.current
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
        logger.debug("Totale pagamenti: " + Helpers::ApplicationHelper.currency(self.totale_pagamenti))
        if Helpers::ApplicationHelper.currency(self.importo) != Helpers::ApplicationHelper.currency(self.totale_pagamenti)
          logger.debug("Importo fattura: " + sprintf("%8.20f", self.importo))
          logger.debug("Totale pagamenti: " + sprintf("%8.20f", self.totale_pagamenti))
          errors.add(:importo, "L'importo della fattura non corrisponde al totale dei pagamenti.")
        end
      end
    end
    
  end

end
