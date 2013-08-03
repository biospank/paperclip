# encoding: utf-8

require 'app/views/scadenzario/report_fornitori_notebook_mgr'

module Views
  module Scadenzario
    module ReportFornitoriFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing Scadenzario ReportFornitoriFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_SCADENZARIO_FORNITORI_NOTEBOOK_MGR', self, :extends => Views::Scadenzario::ReportFornitoriNotebookMgr)
        report_scadenzario_fornitori_notebook_mgr.ui()

      end

      def init_folder()
        # noop
        
      end
      
    end
  end
end
