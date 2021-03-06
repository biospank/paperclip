# encoding: utf-8

module Models
  class PagamentoFatturaFornitore < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :pagamenti_fatture_fornitori
    belongs_to :fattura_fornitore, :foreign_key => 'fattura_fornitore_id'
    belongs_to :tipo_pagamento, :foreign_key => 'tipo_pagamento_id'
    belongs_to :banca, :foreign_key => 'banca_id'
    belongs_to :maxi_pagamento_fornitore, :class_name => 'Models::MaxiPagamentoFornitore', :foreign_key => 'maxi_pagamento_fornitore_id'
    has_one    :pagamento_prima_nota, :class_name => 'Models::PagamentoPrimaNota', :foreign_key => 'pagamento_fattura_fornitore_id', :dependent => :destroy
    has_one    :pagamento_partita_doppia, :class_name => 'Models::PagamentoPartitaDoppia', :foreign_key => 'pagamento_fattura_fornitore_id', :dependent => :destroy
    has_one    :scrittura, :through => :pagamento_prima_nota
    has_one    :scrittura_pd, :through => :pagamento_partita_doppia, :source => :scrittura

    validates_exclusion_of :importo,
      :in => [0],
      :message => "L'importo deve essere diverso da 0."

    validates_presence_of :data_pagamento, 
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :tipo_pagamento,
      :message => "Inserire il codice pagamento oppure premere F5 per la ricerca."

    def before_validation_on_create
      self.data_registrazione = Date.today
      self.registrato_in_prima_nota = 0
    end

    def congelato?
      return (scrittura and scrittura.congelata?)
    end
    
    def parziale?
      return maxi_pagamento_fornitore
    end
    
    def compatibile?(nota_di_credito=false)
      res = true
      if(self.banca and self.tipo_pagamento)
        if(nota_di_credito)
          if(self.tipo_pagamento.nc_banca_dare == 0 and self.tipo_pagamento.nc_banca_avere == 0)
            res = false
          end
        else
          if(self.tipo_pagamento.banca_dare == 0 and self.tipo_pagamento.banca_avere == 0)
            res = false
          end
        end
      end
      return res
    end
    
    protected
    
    def validate()
      if maxi_pagamento = parziale?
        if self.importo > maxi_pagamento.residuo
          errors.add(:importo, "L'importo non puo' superare il valore residuo del parziale.")
        end
      end
    end
    
  end
end
