# encoding: utf-8
require 'app/views/magazzino/report_notebook_mgr'

module Views
  module Magazzino
    module ReportFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing Magazzino ReportFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_NOTEBOOK_MGR', self, :extends => Views::Magazzino::ReportNotebookMgr)
        report_notebook_mgr.ui()

        map_events(self)

      end

      def init_folder()
        report_notebook_mgr.init_folders()
      end


    end
  end
end
