# encoding: utf-8

require 'app/views/anagrafica/report_categoria_notebook_mgr'

module Views
  module Anagrafica
    module ReportFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing Anagrafica ReportFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_CATEGORIA_NOTEBOOK_MGR', self, :extends => Views::Anagrafica::ReportCategoriaNotebookMgr)
        report_categoria_notebook_mgr.ui()

      end

    end
  end
end
