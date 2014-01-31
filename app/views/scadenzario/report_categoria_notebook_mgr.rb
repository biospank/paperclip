# encoding: utf-8

require 'app/helpers/scadenzario_helper'
require 'app/views/scadenzario/report_clienti_folder'
require 'app/views/scadenzario/report_fornitori_folder'
require 'app/views/scadenzario/report_liquidazione_iva_folder'

module Views
  module Scadenzario
    module ReportCategoriaNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing Scadenzario ReportCategoriaNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_SCADENZARIO_CLIENTI_FOLDER', self, :extends => Views::Scadenzario::ReportClientiFolder)
        report_scadenzario_clienti_folder.ui()
        xrc.find('REPORT_SCADENZARIO_FORNITORI_FOLDER', self, :extends => Views::Scadenzario::ReportFornitoriFolder)
        report_scadenzario_fornitori_folder.ui()
        xrc.find('REPORT_LIQUIDAZIONE_IVA_FOLDER', self, :extends => Views::Scadenzario::ReportLiquidazioneIvaFolder)
        report_liquidazione_iva_folder.ui()
        
      end

      def report_categoria_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def report_categoria_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::ScadenzarioHelper::WXBRA_REPORT_SCADENZARIO_CLIENTI_FOLDER
          report_scadenzario_clienti_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_REPORT_SCADENZARIO_FORNITORI_FOLDER
          report_scadenzario_fornitori_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_REPORT_LIQUIDAZIONE_IVA_FOLDER
          report_liquidazione_iva_folder().init_folder()
          
        end
        evt.skip()
      end
    
    end
  end
end
