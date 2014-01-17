# encoding: utf-8

require 'app/helpers/fatturazione_helper'
require 'app/views/fatturazione/report_estratto_folder'
require 'app/views/fatturazione/report_fatture_folder'
require 'app/views/fatturazione/report_da_fatturare_folder'
require 'app/views/fatturazione/report_corrispettivi_folder'
require 'app/views/fatturazione/report_flussi_folder'

module Views
  module Fatturazione
    module ReportNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing ReportNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('REPORT_ESTRATTO_FOLDER', self, :extends => Views::Fatturazione::ReportEstrattoFolder)
        report_estratto_folder.ui()
        xrc.find('REPORT_FATTURE_FOLDER', self, :extends => Views::Fatturazione::ReportFattureFolder)
        report_fatture_folder.ui()
        xrc.find('REPORT_DA_FATTURARE_FOLDER', self, :extends => Views::Fatturazione::ReportDaFatturareFolder)
        report_da_fatturare_folder.ui()
        xrc.find('REPORT_CORRISPETTIVI_FOLDER', self, :extends => Views::Fatturazione::ReportCorrispettiviFolder)
        report_corrispettivi_folder.ui()
        xrc.find('REPORT_FLUSSI_FOLDER', self, :extends => Views::Fatturazione::ReportFlussiFolder)
        report_flussi_folder.ui()
        
        set_page_text(Helpers::FatturazioneHelper::WXBRA_REPORT_ESTRATTO_FOLDER, 'Estratto ' + Models::NotaSpese::INTESTAZIONE_PLURALE[configatron.pre_fattura.intestazione.to_i] + '/Fatture')
      end

      def report_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def report_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::FatturazioneHelper::WXBRA_REPORT_ESTRATTO_FOLDER
          report_estratto_folder().init_folder()
#        when Helpers::FatturazioneHelper::WXBRA_REPORT_PARTITARIO_FOLDER
#          report_partitario_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_REPORT_FATTURE_FOLDER
          report_fatture_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_REPORT_DA_FATTURARE_FOLDER
          report_da_fatturare_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_REPORT_CORRISPETTIVI_FOLDER
          report_corrispettivi_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_REPORT_FLUSSI_FOLDER
          report_flussi_folder().init_folder()
          
        end
        evt.skip()
      end

      def init_folders()
        
      end
    end
  end
end
