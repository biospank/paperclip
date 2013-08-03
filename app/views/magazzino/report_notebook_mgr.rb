# encoding: utf-8

require 'app/helpers/magazzino_helper'
require 'app/views/magazzino/report_ordini_folder'
require 'app/views/magazzino/report_movimenti_folder'
require 'app/views/magazzino/report_giacenze_folder'

module Views
  module Magazzino
    module ReportNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing ReportNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_ORDINI_FOLDER', self, :extends => Views::Magazzino::ReportOrdiniFolder)
        report_ordini_folder.ui()
        xrc.find('REPORT_MOVIMENTI_FOLDER', self, :extends => Views::Magazzino::ReportMovimentiFolder)
        report_movimenti_folder.ui()
        xrc.find('REPORT_GIACENZE_FOLDER', self, :extends => Views::Magazzino::ReportGiacenzeFolder)
        report_giacenze_folder.ui()
        
      end

      def report_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def report_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::MagazzinoHelper::WXBRA_REPORT_ORDINI_FOLDER
          report_ordini_folder().init_folder()
        when Helpers::MagazzinoHelper::WXBRA_REPORT_MOVIMENTI_FOLDER
          report_movimenti_folder().init_folder()
        when Helpers::MagazzinoHelper::WXBRA_REPORT_GIACENZE_FOLDER
          report_giacenze_folder().init_folder()
          
        end
        evt.skip()
      end

      def init_folders()
        
      end
    end
  end
end
