# encoding: utf-8

require 'app/models/base'

module Models
  class MaxiPagamentoFornitore < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model
    
    set_table_name :maxi_pagamenti_fornitori

    attr_accessor :residuo
    
    belongs_to :azienda
    belongs_to :tipo_pagamento, :foreign_key => 'tipo_pagamento_id'
    belongs_to :banca, :foreign_key => 'banca_id'
    has_many   :pagamenti_fattura_fornitore, :class_name => 'Models::PagamentoFatturaFornitore', :foreign_key => 'maxi_pagamento_fornitore_id'
    has_many   :pagamenti_prima_nota, :class_name => 'Models::PagamentoPrimaNota', :foreign_key => 'maxi_pagamento_fornitore_id'
    has_many   :pagamenti_partita_doppia, :class_name => 'Models::PagamentoPartitaDoppia', :foreign_key => 'maxi_pagamento_fornitore_id'
  
    validates_exclusion_of :importo,
      :in => [0],
      :message => "L'importo deve essere diverso da 0."

    validates_presence_of :tipo_pagamento,
      :message => "Inserire la tipologia di pagamento."

    validates_presence_of :data_pagamento, 
      :message => "Data inesistente o formalmente errata."

    
    def before_create
      self.azienda = Azienda.current
      self.data_registrazione = Date.today
    end

    def calcola_residuo()
        totale_pagamenti_multipli = self.pagamenti_fattura_fornitore.sum(:importo, :conditions => ["maxi_pagamento_fornitore_id = ?", self])
        self.residuo = (self.importo - totale_pagamenti_multipli)
        self
    end
    
    def registrato_in_prima_nota?
      self.chiuso?
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
        
  end
end