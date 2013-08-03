# encoding: utf-8

require 'app/helpers/scadenzario_helper'
require 'app/views/scadenzario/report_estratto_fornitori_folder'
require 'app/views/scadenzario/report_partitario_fornitori_folder'
require 'app/views/scadenzario/report_saldi_fornitori_folder'
require 'app/views/scadenzario/report_scadenze_fornitori_folder'

module Views
  module Scadenzario
    module ReportFornitoriNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing Scadenzario ReportFornitoriNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_ESTRATTO_FORNITORI_FOLDER', self, :extends => Views::Scadenzario::ReportEstrattoFornitoriFolder)
        report_estratto_fornitori_folder.ui()
        xrc.find('REPORT_PARTITARIO_FORNITORI_FOLDER', self, :extends => Views::Scadenzario::ReportPartitarioFornitoriFolder)
        report_partitario_fornitori_folder.ui()
        xrc.find('REPORT_SALDI_FORNITORI_FOLDER', self, :extends => Views::Scadenzario::ReportSaldiFornitoriFolder)
        report_saldi_fornitori_folder.ui()
        xrc.find('REPORT_SCADENZE_FORNITORI_FOLDER', self, :extends => Views::Scadenzario::ReportScadenzeFornitoriFolder)
        report_scadenze_fornitori_folder.ui()
        
      end

      def report_fornitori_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def report_fornitori_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::ScadenzarioHelper::WXBRA_ESTRATTO_REPORT_FORNITORI_FOLDER
          report_estratto_fornitori_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_PARTITARIO_REPORT_FORNITORI_FOLDER
          report_partitario_fornitori_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_SALDI_REPORT_FORNITORI_FOLDER
          report_saldi_fornitori_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_SCADENZE_REPORT_FORNITORI_FOLDER
          report_scadenze_fornitori_folder().init_folder()
          
        end
        evt.skip()
      end
    
      
    end
  end
end
