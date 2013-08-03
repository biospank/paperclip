# encoding: utf-8

require 'app/helpers/scadenzario_helper'
require 'app/views/scadenzario/report_estratto_clienti_folder'
require 'app/views/scadenzario/report_partitario_clienti_folder'
require 'app/views/scadenzario/report_saldi_clienti_folder'
require 'app/views/scadenzario/report_scadenze_clienti_folder'

module Views
  module Scadenzario
    module ReportClientiNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing Scadenzario ReportClientiNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_ESTRATTO_CLIENTI_FOLDER', self, :extends => Views::Scadenzario::ReportEstrattoClientiFolder)
        report_estratto_clienti_folder.ui()
        xrc.find('REPORT_PARTITARIO_CLIENTI_FOLDER', self, :extends => Views::Scadenzario::ReportPartitarioClientiFolder)
        report_partitario_clienti_folder.ui()
        xrc.find('REPORT_SALDI_CLIENTI_FOLDER', self, :extends => Views::Scadenzario::ReportSaldiClientiFolder)
        report_saldi_clienti_folder.ui()
        xrc.find('REPORT_SCADENZE_CLIENTI_FOLDER', self, :extends => Views::Scadenzario::ReportScadenzeClientiFolder)
        report_scadenze_clienti_folder.ui()
        
      end

      def report_clienti_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def report_clienti_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::ScadenzarioHelper::WXBRA_ESTRATTO_REPORT_CLIENTI_FOLDER
          report_estratto_clienti_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_PARTITARIO_REPORT_CLIENTI_FOLDER
          report_partitario_clienti_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_SALDI_REPORT_CLIENTI_FOLDER
          report_saldi_clienti_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_SCADENZE_REPORT_CLIENTI_FOLDER
          report_scadenze_clienti_folder().init_folder()
          
        end
        evt.skip()
      end
    
      
    end
  end
end
