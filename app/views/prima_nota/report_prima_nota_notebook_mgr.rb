# encoding: utf-8

require 'app/helpers/prima_nota_helper'
require 'app/views/prima_nota/report_stampe_folder'
require 'app/views/prima_nota/report_partitario_folder'

module Views
  module PrimaNota
    module ReportPrimaNotaNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing ReportPrimaNotaNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_STAMPE_FOLDER', self, :extends => Views::PrimaNota::ReportStampeFolder)
        report_stampe_folder.ui()
        xrc.find('REPORT_PARTITARIO_FOLDER', self, :extends => Views::PrimaNota::ReportPartitarioFolder)
        report_partitario_folder.ui()
        
      end

      def report_prima_nota_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def report_prima_nota_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::PrimaNotaHelper::WXBRA_REPORT_STAMPE_FOLDER
          report_stampe_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_REPORT_PARTITARIO_FOLDER
          report_partitario_folder().init_folder()
          
        end
        evt.skip()
      end

      def init_folders()
        
      end
    end
  end
end
