# encoding: utf-8

require 'app/helpers/scadenzario_helper'
require 'app/views/scadenzario/report_iva_folder'
require 'app/views/scadenzario/report_acquisti_folder'
require 'app/views/scadenzario/report_vendite_folder'
require 'app/views/scadenzario/report_corrispettivi_folder'

module Views
  module Scadenzario
    module ReportLiquidazioniNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      def ui
        
        logger.debug('initializing Scadenzario ReportLiquidazioniNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_IVA_FOLDER', self, :extends => Views::Scadenzario::ReportIvaFolder)
        report_iva_folder.ui()
        xrc.find('REPORT_ACQUISTI_FOLDER', self, :extends => Views::Scadenzario::ReportAcquistiFolder)
        report_acquisti_folder.ui()
        xrc.find('REPORT_VENDITE_FOLDER', self, :extends => Views::Scadenzario::ReportVenditeFolder)
        report_vendite_folder.ui()
        xrc.find('REPORT_CORRISPETTIVI_FOLDER', self, :extends => Views::Scadenzario::ReportCorrispettiviFolder)
        report_corrispettivi_folder.ui()
        
      end

      def report_liquidazioni_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def report_liquidazioni_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::ScadenzarioHelper::WXBRA_IVA_REPORT_FOLDER
          report_iva_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_ACQUITI_REPORT_FOLDER
          report_acquisti_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_VENDITE_REPORT_FOLDER
          report_vendite_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_CORRISPETTIVI_REPORT_FOLDER
          report_corrispettivi_folder().init_folder()
          
        end
        evt.skip()
      end
    
      def ricerca(filtro)
        begin
          report_acquisti_folder.ricerca(filtro)
          report_vendite_folder.ricerca(filtro)
          report_corrispettivi_folder.ricerca(filtro)
          report_iva_folder.riepilogo(filtro)
        rescue Exception => e
          log_error(self, e)
        end
      end

      def stampa(filtro)
        Wx::BusyCursor.busy() do

          report_iva_folder.stampa(filtro)
          report_acquisti_folder.stampa(filtro)
          report_vendite_folder.stampa(filtro)
          report_corrispettivi_folder.stampa(filtro)

          merge_all([
              :report_acquisti,
              :report_vendite,
              :report_corrispettivi,
              :report_iva
            ],
            :output => :liquidazione_iva
          )

        end

      end

      def reset_folder()
        report_iva_folder.reset_folder
        report_acquisti_folder.reset_folder
        report_vendite_folder.reset_folder
        report_corrispettivi_folder.reset_folder
      end

    end
  end
end
