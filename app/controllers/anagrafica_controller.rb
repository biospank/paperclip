# encoding: utf-8

module Controllers
  module AnagraficaController
    include Controllers::BaseController

    # clienti
    def save_cliente()
      cliente.save
    end

    def delete_cliente()
      cliente.destroy
    end

    def search_for_clienti()
      Cliente.search_for(filtro.ricerca, nil, build_clienti_dialog_conditions())
    end

    def build_clienti_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
    
      {:conditions => [query_str.join(' AND '), *parametri], 
       :order => 'denominazione'}
    end

    def report_clienti()
      data_matrix = []

      Cliente.search(:all, build_clienti_report_conditions()).each do |cliente|
        dati_cliente = []
        dati_cliente << cliente.denominazione
        dati_cliente << cliente.cod_fisc
        dati_cliente << cliente.p_iva
        dati_cliente << cliente.indirizzo
        dati_cliente << cliente.citta
        dati_cliente << cliente.telefono
        dati_cliente << cliente.cellulare
        dati_cliente << cliente.attivo
        dati_cliente << cliente.note

        data_matrix << dati_cliente

      end
      
      data_matrix
    end    
 
    def build_clienti_report_conditions()
      query_str = []
      parametri = []
      
      query_str << 'attivo = 1' if filtro.attivi
    
      {:conditions => [query_str.join(' AND '), *parametri], 
       :order => 'denominazione'}
    end
    
    # fornitori
    def save_fornitore()
      fornitore.save
    end

    def delete_fornitore()
      fornitore.destroy
    end

    def search_for_fornitori()
      Fornitore.search_for(filtro.ricerca, nil, build_fornitori_dialog_conditions())
    end

    def build_fornitori_dialog_conditions()
      query_str = []
      parametri = []
      
      filtro.build_conditions(query_str, parametri) if filtro
    
      {:conditions => [query_str.join(' AND '), *parametri], 
       :order => 'denominazione'}
    end

    def report_fornitori()
      data_matrix = []

      Fornitore.search(:all, build_fornitori_report_conditions()).each do |fornitore|
        dati_fornitore = []
        dati_fornitore << fornitore.denominazione
        dati_fornitore << fornitore.cod_fisc
        dati_fornitore << fornitore.p_iva
        dati_fornitore << fornitore.indirizzo
        dati_fornitore << fornitore.citta
        dati_fornitore << fornitore.telefono
        dati_fornitore << fornitore.cellulare
        dati_fornitore << fornitore.attivo
        dati_fornitore << fornitore.note

        data_matrix << dati_fornitore

      end
      
      data_matrix
    end    
 
    def build_fornitori_report_conditions()
      query_str = []
      parametri = []
      
      query_str << 'attivo = 1' if filtro.attivi
    
      {:conditions => [query_str.join(' AND '), *parametri], 
       :order => 'denominazione'}
    end
    
  end
end