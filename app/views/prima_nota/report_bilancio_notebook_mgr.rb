# encoding: utf-8

require 'app/helpers/prima_nota_helper'
require 'app/views/prima_nota/bilancio_di_verifica_folder'
require 'app/views/prima_nota/report_bilancio_partitario_folder'

module Views
  module PrimaNota
    module ReportBilancioNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing ReportBilancioNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('BILANCIO_DI_VERIFICA_FOLDER', self, :extends => Views::PrimaNota::BilancioDiVerificaFolder)
        bilancio_di_verifica_folder.ui()
        xrc.find('REPORT_PARTITARIO_FOLDER', self, :extends => Views::PrimaNota::ReportPartitarioFolder)
        report_partitario_folder.ui()
        
      end

      def report_bilancio_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def report_bilancio_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::PrimaNotaHelper::WXBRA_BILANCIO_DI_VERIFICA_FOLDER
          bilancio_di_verifica_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_REPORT_BILANCIO_PARTITARIO_FOLDER
          report_bilancio_partitario_folder().init_folder()
          
        end
        evt.skip()
      end

      def init_folders()
        
      end
    end
  end
end
