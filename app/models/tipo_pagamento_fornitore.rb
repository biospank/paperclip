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

    
    def modificabile?
      num = 0
      num = Models::PagamentoFatturaFornitore.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num += Models::MaxiPagamentoFornitore.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num == 0
    end
  
  end
end