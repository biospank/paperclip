# encoding: utf-8

module Models
  class Filtro 
    include Base::Model
#    extend ActiveRecord::Validations::ClassMethods

    attr_accessor :ricerca,  # indica il testo inserito dall'utente 
                  :categoria, # indica la categoria [clienti, fornitori]
                  :attivi, # indica tutte le occorrenze che hanno attivo = 1
                  :attive, # indica tutte le occorrenze che hanno attiva = 1
                  :dettagliata, # viene usata nel report anagrafica per la stampa dettagliata
                  :anno, # viene usato nelle dialog
                  :mese, # corrispettivi
                  :giorno, # corrispettivi
                  :periodo, # usato nei repord delle liquidazioni iva
                  :aliquota, # corrispettivi
                  :descrizione_aliquota, # corrispettivi
                  :pdc_dare, # corrispettivi
                  :descrizione_pdc_dare, # corrispettivi
                  :pdc_avere, # corrispettivi
                  :descrizione_pdc_avere, # corrispettivi
                  :descrizione_pdc, # corrispettivi
                  :tutti, #corrispettivi dialog
                  :corrispettivi, # viene utilizzato nel report dei corrispettivi
                  :cliente, # viene usato nelle dialog
                  :fornitore, # viene usato nelle dialog
                  :sql_criteria, # viene usato per condizioni aggiuntive alla query di ricerca nelle dialog
                  :dal, # viene usato nei riport per indicare la data di partenza
                  :al,  # viene usato nei riport per indicare la data di arrivo
                  :residuo, # residuo viene utilizzato per calcolare il residuo degli anni precedenti
                  :causale, # viene utilizzato nei report
                  :banca, # viene utilizzato nei report
                  :prodotto, # viene utilizzato nei report
                  :fattura_num, # viene utilizzato nei report dello scadenzario
                  :modalita,  # viene utilizzato nei report dello scadenzario
                  :tipo_pagamento,  # viene utilizzato nei report dello scadenzario
                  :partita, # viene utilizzato nei report delle scritture
                  :stampa_residuo, # viene utilizzato nei report delle scritture
                  :data_storico_residuo, # viene utilizzato nei report delle scritture
                  :saldi_aperti, # utilizzato nei report dello scadenzario
                  :riepilogo, # utilizzato nei report della fatturazione
                  :movimento # utilizzato nei report del magazzino
                  
#    validates_presence_of :data_emissione, 
#      :message => "Data inesistente o formalmente errata."
    
    def build_conditions(query_str, parametri)
      if self.anno
        query_str << "#{to_sql_year('data_emissione')} = ? "
        parametri << self.anno
      end
      
      query_str << self.sql_criteria if self.sql_criteria
      query_str << 'attivo = 1' if attivi
      query_str << 'attiva = 1' if attive
      query_str << "categoria_id = #{categoria}" if categoria

      self.cliente.build_conditions(query_str, parametri) if self.cliente
      self.fornitore.build_conditions(query_str, parametri) if self.fornitore
      
    end
  end
end