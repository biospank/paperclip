# encoding: utf-8

require 'app/views/prima_nota/report_bilancio_notebook_mgr'

module Views
  module PrimaNota
    module ReportBilancioFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing PrimaNota ReportBilancioFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_BILANCIO_NOTEBOOK_MGR', self, :extends => Views::PrimaNota::ReportBilancioNotebookMgr)
        report_bilancio_notebook_mgr.ui()

        map_events(self)

      end

      def init_folder()
        report_bilancio_notebook_mgr.init_folders()
      end
      
    end
  end
end

