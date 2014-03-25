# encoding: utf-8

require 'app/helpers/prima_nota_helper'
require 'app/views/prima_nota/report_prima_nota_folder'
require 'app/views/prima_nota/report_bilancio_folder'

module Views
  module PrimaNota
    module ReportNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper

      def ui

        logger.debug('initializing ReportNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_PRIMA_NOTA_FOLDER', self, :extends => Views::PrimaNota::ReportPrimaNotaFolder)
        report_prima_nota_folder.ui()
        xrc.find('REPORT_BILANCIO_FOLDER', self, :extends => Views::PrimaNota::ReportBilancioFolder)
        report_bilancio_folder.ui()

        subscribe(:evt_bilancio_attivo) do |data|
          data ?  enable_widgets([report_bilancio_folder]) : disable_widgets([report_bilancio_folder])
        end
      end

      def report_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def report_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::PrimaNotaHelper::WXBRA_REPORT_PRIMA_NOTA_FOLDER
          report_prima_nota_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_REPORT_BILANCIO_FOLDER
          report_bilancio_folder().init_folder()

        end
        evt.skip()
      end

      def init_folders()

      end
    end
  end
end
