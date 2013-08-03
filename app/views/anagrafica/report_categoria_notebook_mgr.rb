# encoding: utf-8

require 'app/helpers/anagrafica_helper'
require 'app/views/anagrafica/report_clienti_folder'
require 'app/views/anagrafica/report_fornitori_folder'

module Views
  module Anagrafica
    module ReportCategoriaNotebookMgr
      include Views::Base::View
      
      def ui
        
        logger.debug('initializing Anagrafica ReportCategoriaNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_CLIENTI_FOLDER', self, :extends => Views::Anagrafica::ReportClientiFolder)
        report_clienti_folder.ui()
        xrc.find('REPORT_FORNITORI_FOLDER', self, :extends => Views::Anagrafica::ReportFornitoriFolder)
        report_fornitori_folder.ui()
        
      end

      def report_categoria_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def report_categoria_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::AnagraficaHelper::WXBRA_REPORT_CLIENTI_FOLDER
          report_clienti_folder().init_folder()
        when Helpers::AnagraficaHelper::WXBRA_REPORT_FORNITORI_FOLDER
          report_fornitori_folder().init_folder()
          
        end
        evt.skip()
      end
    
    end
  end
end
