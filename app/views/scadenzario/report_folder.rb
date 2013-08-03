# encoding: utf-8

require 'app/views/scadenzario/report_categoria_notebook_mgr'

module Views
  module Scadenzario
    module ReportFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing Scadenzario ReportFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_CATEGORIA_NOTEBOOK_MGR', self, :extends => Views::Scadenzario::ReportCategoriaNotebookMgr)
        report_categoria_notebook_mgr.ui()

        map_events(self)

      end

    end
  end
end
