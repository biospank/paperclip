# encoding: utf-8

require 'app/helpers/scadenzario_helper'
require 'app/views/scadenzario/scadenzario_clienti_folder'
require 'app/views/scadenzario/scadenzario_fornitori_folder'
require 'app/views/scadenzario/scadenzario_clienti_bilancio_folder'
require 'app/views/scadenzario/scadenzario_fornitori_bilancio_folder'
require 'app/views/scadenzario/impostazioni_folder'
require 'app/views/scadenzario/report_folder'

module Views
  module Scadenzario
    module ScadenzarioNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper

      def ui
        controller :base
        logger.debug('initializing ScadenzarioNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()

        if configatron.bilancio.attivo
          xrc.find('SCADENZARIO_CLIENTI_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
          end
          xrc.find('SCADENZARIO_FORNITORI_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
          end

          xrc.find('SCADENZARIO_CLIENTI_BILANCIO_FOLDER', self,
            :extends => Views::Scadenzario::ScadenzarioClientiBilancioFolder,
            :alias => :scadenzario_clienti_folder)
          scadenzario_clienti_folder.ui()
          xrc.find('SCADENZARIO_FORNITORI_BILANCIO_FOLDER', self,
            :extends => Views::Scadenzario::ScadenzarioFornitoriBilancioFolder,
            :alias => :scadenzario_fornitori_folder)
          scadenzario_fornitori_folder.ui()
        else
          xrc.find('SCADENZARIO_CLIENTI_FOLDER', self, :extends => Views::Scadenzario::ScadenzarioClientiFolder)
          scadenzario_clienti_folder.ui()
          xrc.find('SCADENZARIO_FORNITORI_FOLDER', self, :extends => Views::Scadenzario::ScadenzarioFornitoriFolder)
          scadenzario_fornitori_folder.ui()

          xrc.find('SCADENZARIO_CLIENTI_BILANCIO_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER + 1)
          end
          xrc.find('SCADENZARIO_FORNITORI_BILANCIO_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER + 1)
          end

        end

        xrc.find('IMPOSTAZIONI_FOLDER', self, :extends => Views::Scadenzario::ImpostazioniFolder)
        impostazioni_folder.ui()
        xrc.find('REPORT_FOLDER', self, :extends => Views::Scadenzario::ReportFolder)
        report_folder.ui()
      end

      def scadenzario_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        if ctrl.locked?
          Wx::message_box("Completare la chiusura dei movimenti in sospeso oppure,\npremere il pulsante indietro.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          evt.veto()
        end
        #evt.skip()
      end

      def scadenzario_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER
          scadenzario_clienti_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
          scadenzario_fornitori_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER
          impostazioni_folder().init_folder()
        when Helpers::ScadenzarioHelper::WXBRA_REPORT_SCADENZARIO_FOLDER
          report_folder().init_folder()

        end
        evt.skip()
      end

    end
  end
end
