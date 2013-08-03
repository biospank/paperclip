# encoding: utf-8

require 'app/views/prima_nota/report_notebook_mgr'
require 'app/views/dialog/rif_maxi_incassi_dialog'
require 'app/views/dialog/rif_maxi_pagamenti_dialog'

module Views
  module PrimaNota
    module ReportFolder
      include Views::Base::Folder
      def ui
        logger.debug('initializing PrimaNota ReportFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_NOTEBOOK_MGR', self, :extends => Views::PrimaNota::ReportNotebookMgr)
        report_notebook_mgr.ui()

        map_events(self)

      end

      def init_folder()
        report_notebook_mgr.init_folders()
      end
      
    end
  end
end

