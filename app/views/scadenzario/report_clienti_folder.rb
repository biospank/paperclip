# encoding: utf-8

require 'app/views/scadenzario/report_clienti_notebook_mgr'

module Views
  module Scadenzario
    module ReportClientiFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing Scadenzario ReportClientiFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_SCADENZARIO_CLIENTI_NOTEBOOK_MGR', self, :extends => Views::Scadenzario::ReportClientiNotebookMgr)
        report_scadenzario_clienti_notebook_mgr.ui()

      end

      def init_folder()
        # noop
      end
      
    end
  end
end
