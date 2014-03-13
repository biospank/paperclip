# encoding: utf-8

require 'app/views/prima_nota/report_prima_nota_notebook_mgr'

module Views
  module PrimaNota
    module ReportPrimaNotaFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing PrimaNota ReportPrimaNotaFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_PRIMA_NOTA_NOTEBOOK_MGR', self, :extends => Views::PrimaNota::ReportPrimaNotaNotebookMgr)
        report_prima_nota_notebook_mgr.ui()

        map_events(self)

      end

      def init_folder()
        report_prima_nota_notebook_mgr.init_folders()
      end
      
    end
  end
end

