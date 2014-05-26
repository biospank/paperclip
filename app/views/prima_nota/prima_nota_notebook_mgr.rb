# encoding: utf-8

require 'app/helpers/prima_nota_helper'
require 'app/views/prima_nota/scritture_folder'
require 'app/views/prima_nota/causali_folder'
require 'app/views/prima_nota/causali_bilancio_folder'
require 'app/views/prima_nota/pdc_folder'
require 'app/views/prima_nota/report_folder'

module Views
  module PrimaNota
    module PrimaNotaNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper

      def ui

        logger.debug('initializing PrimaNotaNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('SCRITTURE_FOLDER', self, :extends => Views::PrimaNota::ScrittureFolder)
        scritture_folder.ui()
        if configatron.bilancio.attivo
          xrc.find('CAUSALI_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
          end

          xrc.find('CAUSALI_BILANCIO_FOLDER', self,
            :extends => Views::PrimaNota::CausaliBilancioFolder,
            :alias => :causali_folder)
          causali_folder.ui()

          xrc.find('PDC_FOLDER', self, :extends => Views::PrimaNota::PdcFolder)
          pdc_folder.ui()
        else
          xrc.find('CAUSALI_FOLDER', self, :extends => Views::PrimaNota::CausaliFolder)
          causali_folder.ui()

          xrc.find('CAUSALI_BILANCIO_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER + 1)
          end

          xrc.find('PDC_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER + 1)
          end

        end

        xrc.find('REPORT_FOLDER', self, :extends => Views::PrimaNota::ReportFolder)
        report_folder.ui()

        # subscribe(:evt_bilancio_attivo) do |data|
        #   data ? enable_widgets([pdc_folder]) : disable_widgets([pdc_folder])
        # end

      end

      def prima_nota_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def prima_nota_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER
          scritture_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER
          causali_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_PDC_FOLDER
          # porcata
          if configatron.bilancio.attivo
            pdc_folder().init_folder()
          else
            report_folder().init_folder()
          end
        when Helpers::PrimaNotaHelper::WXBRA_REPORT_FOLDER
          report_folder().init_folder()

        end
        evt.skip()
      end

    end
  end
end
