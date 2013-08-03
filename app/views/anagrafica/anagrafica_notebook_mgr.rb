# encoding: utf-8

require 'app/helpers/anagrafica_helper'
require 'app/views/anagrafica/anagrafica_folder'
require 'app/views/anagrafica/report_folder'

module Views
  module Anagrafica
    module AnagraficaNotebookMgr
      include Views::Base::View

      def ui
        logger.debug('initializing AnagraficaNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('ANAGRAFICA_FOLDER', self, :extends => Views::Anagrafica::AnagraficaFolder)
        anagrafica_folder.ui()
        xrc.find('REPORT_FOLDER', self, :extends => Views::Anagrafica::ReportFolder)
        report_folder.ui()
      end
      
      # gestione eventi
      def anagrafica_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def anagrafica_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::AnagraficaHelper::WXBRA_ANAGRAFICA_FOLDER
          anagrafica_folder.init_folder()
        end
        evt.skip()
      end


    end
  end
end
