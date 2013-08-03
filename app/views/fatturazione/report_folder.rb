# encoding: utf-8

require 'app/views/fatturazione/report_notebook_mgr'

module Views
  module Fatturazione
    module ReportFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing Fatturazione ReportFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_NOTEBOOK_MGR', self, :extends => Views::Fatturazione::ReportNotebookMgr)
        report_notebook_mgr.ui()

        map_events(self)

      end

      def init_folder()
        report_notebook_mgr.init_folders()
      end
      
    end
  end
end
