# encoding: utf-8

require 'app/helpers/fatturazione_helper'
require 'app/views/fatturazione/nota_spese_folder'
require 'app/views/fatturazione/fattura_folder'
require 'app/views/fatturazione/corrispettivi_folder'
require 'app/views/fatturazione/corrispettivi_bilancio_folder'
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
        if configatron.bilancio.attivo
          xrc.find('CORRISPETTIVI_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
          end

          xrc.find('CORRISPETTIVI_BILANCIO_FOLDER', self,
            :extends => Views::Fatturazione::CorrispettiviBilancioFolder,
            :alias => :corrispettivi_folder)
          corrispettivi_folder.ui()
        else
          xrc.find('CORRISPETTIVI_FOLDER', self, :extends => Views::Fatturazione::CorrispettiviFolder)
          corrispettivi_folder.ui()

          xrc.find('CORRISPETTIVI_BILANCIO_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER + 1)
          end

        end

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
        evt.skip()
      end

      def fatturazione_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::FatturazioneHelper::WXBRA_NOTA_SPESE_FOLDER
          nota_spese_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_FATTURA_FOLDER
          fattura_folder().init_folder()
          fattura_folder().refresh()
        when Helpers::FatturazioneHelper::WXBRA_DDT_FOLDER
          ddt_folder().init_folder()
        when Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER
          corrispettivi_folder().init_folder()
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
