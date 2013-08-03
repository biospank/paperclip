# encoding: utf-8

require 'app/helpers/fatturazione_helper'
require 'app/views/fatturazione/nota_spese_folder'
require 'app/views/fatturazione/fattura_folder'
require 'app/views/fatturazione/ddt_folder'
require 'app/views/fatturazione/impostazioni_folder'
require 'app/views/fatturazione/report_folder'

module Views
  module Fatturazione
    module FatturazioneNotebookMgr
      include Views::Base::View
      
      def ui
        logger.debug('initializing FatturazioneNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('NOTA_SPESE_FOLDER', self, :extends => Views::Fatturazione::NotaSpeseFolder)
        nota_spese_folder.ui()
        xrc.find('FATTURA_FOLDER', self, :extends => Views::Fatturazione::FatturaFolder)
        fattura_folder.ui()
        xrc.find('DDT_FOLDER', self, :extends => Views::Fatturazione::DdtFolder)
        ddt_folder.ui()
        xrc.find('IMPOSTAZIONI_FOLDER', self, :extends => Views::Fatturazione::ImpostazioniFolder)
        impostazioni_folder.ui()
        xrc.find('REPORT_FOLDER', self, :extends => Views::Fatturazione::ReportFolder)
        report_folder.ui()

        set_page_text(0, "#{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]}")

        subscribe(:evt_prefattura_changed) do
          set_page_text(0, "#{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]}")
        end

      end

      def fatturazione_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        evt.skip()
      end

      def fatturazione_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::FatturazioneHelper::WXBRA_NOTA_SPESE_FOLDER
          nota_spese_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_FATTURA_FOLDER
          fattura_folder().init_folder()
          fattura_folder().refresh()
        when Helpers::FatturazioneHelper::WXBRA_DDT_FOLDER
          ddt_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_IMPOSTAZIONI_FOLDER
          impostazioni_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_REPORT_FOLDER
          report_folder().init_folder()
          
        end
        evt.skip()
      end
      
    end
  end
end
