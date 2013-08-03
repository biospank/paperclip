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

    
    def modificabile?
      num = 0
      num = Models::PagamentoFatturaCliente.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num += Models::MaxiPagamentoCliente.count(:conditions => ["tipo_pagamento_id = ?", self.id])
      num == 0
    end
  
  end

end