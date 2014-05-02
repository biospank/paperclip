# encoding: utf-8

require 'app/helpers/prima_nota_helper'
require 'app/views/prima_nota/stato_patrimoniale_folder'
require 'app/views/prima_nota/conto_economico_folder'
require 'app/views/prima_nota/dettaglio_clienti_fornitori_folder'

module Views
  module PrimaNota
    module BilancioDiVerificaNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      
      def ui
        
        logger.debug('initializing Bilancio BilancioDiVerificaNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('STATO_PATRIMONIALE_FOLDER', self, :extends => Views::PrimaNota::StatoPatrimonialeFolder)
        stato_patrimoniale_folder.ui()
        xrc.find('CONTO_ECONOMICO_FOLDER', self, :extends => Views::PrimaNota::ContoEconomicoFolder)
        conto_economico_folder.ui()
        xrc.find('DETTAGLIO_CLIENTI_FORNITORI_FOLDER', self, :extends => Views::PrimaNota::DettaglioClientiFornitoriFolder)
        dettaglio_clienti_fornitori_folder.ui()
        
      end

      def bilancio_di_verifica_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def bilancio_di_verifica_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::PrimaNotaHelper::WXBRA_STATO_PATRIMONIALE_FOLDER
          stato_patrimoniale_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_CONTO_ECONOMICO_FOLDER
          conto_economico_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_DETTAGLIO_CLIENTI_FORNITORI_FOLDER
          dettaglio_clienti_fornitori_folder().init_folder()
          
        end
        evt.skip()
      end

      def ricerca(filtro)
        begin
          stato_patrimoniale_folder.ricerca(filtro)
          conto_economico_folder.ricerca(filtro)
          dettaglio_clienti_fornitori_folder.ricerca(filtro)
        rescue Exception => e
          log_error(self, e)
        end
      end

      def ricerca_aggregata(filtro)
        begin
          stato_patrimoniale_folder.ricerca_aggregata(filtro)
          conto_economico_folder.ricerca_aggregata(filtro)
          dettaglio_clienti_fornitori_folder.ricerca(filtro)
        rescue Exception => e
          log_error(self, e)
        end
      end

      def stampa(filtro)
        Wx::BusyCursor.busy() do

          stato_patrimoniale_folder.stampa(filtro)
          conto_economico_folder.stampa(filtro)
          dettaglio_clienti_fornitori_folder.stampa(filtro)

          merge_all([
              :report_stato_patrimoniale,
              :report_conto_economico,
              :report_dettaglio
            ],
            :output => :bilancio
          )

        end

      end

      def init_folder()

      end
      
      def reset_folder()
        stato_patrimoniale_folder.reset_folder
        conto_economico_folder.reset_folder
        dettaglio_clienti_fornitori_folder.reset_folder
      end

    end
  end
end
