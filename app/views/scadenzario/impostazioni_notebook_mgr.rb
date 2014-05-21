# encoding: utf-8

require 'app/helpers/scadenzario_helper'
require 'app/views/scadenzario/incassi_pagamenti_folder'
require 'app/views/scadenzario/incassi_pagamenti_bilancio_folder'
require 'app/views/scadenzario/norma_liquidazioni_folder'

module Views
  module Scadenzario
    module ImpostazioniNotebookMgr
      include Views::Base::View

      def ui

        logger.debug('initializing Scadenzario ImpostazioniNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()

        if configatron.bilancio.attivo
          xrc.find('INCASSI_PAGAMENTI_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::ScadenzarioHelper::WXBRA_INCASSI_PAGAMENTI_FOLDER)
          end

          xrc.find('INCASSI_PAGAMENTI_BILANCIO_FOLDER', self, :extends => Views::Scadenzario::IncassiPagamentiBilancioFolder)
          incassi_pagamenti_bilancio_folder.ui()
        else
          xrc.find('INCASSI_PAGAMENTI_FOLDER', self, :extends => Views::Scadenzario::IncassiPagamentiFolder)
          incassi_pagamenti_folder.ui()

          xrc.find('INCASSI_PAGAMENTI_BILANCIO_FOLDER', self) do |folder|
            # alla rimozione dei folder, quelli presenti vengono rinumerati a partire da zero
            self.delete_page(Helpers::ScadenzarioHelper::WXBRA_INCASSI_PAGAMENTI_FOLDER + 1)
          end

        end

        xrc.find('NORMA_LIQUIDAZIONI_FOLDER', self, :extends => Views::Scadenzario::NormaLiquidazioniFolder)
        norma_liquidazioni_folder.ui()

        subscribe(:evt_new_tipo_incasso) do
          set_selection(Helpers::ScadenzarioHelper::WXBRA_INCASSI_PAGAMENTI_FOLDER)
        end

        subscribe(:evt_new_tipo_pagamento) do
          set_selection(Helpers::ScadenzarioHelper::WXBRA_INCASSI_PAGAMENTI_FOLDER)
        end

        subscribe(:evt_new_norma) do
          set_selection(Helpers::ScadenzarioHelper::WXBRA_NORMA_LIQUIDAZIONI_FOLDER)
        end

      end

      def impostazioni_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def impostazioni_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::ScadenzarioHelper::WXBRA_INCASSI_PAGAMENTI_FOLDER
          if configatron.bilancio.attivo
            incassi_pagamenti_bilancio_folder().init_folder()
          else
            incassi_pagamenti_folder().init_folder()
          end
        when Helpers::ScadenzarioHelper::WXBRA_NORMA_LIQUIDAZIONI_FOLDER
          norma_liquidazioni_folder().init_folder()

        end
        evt.skip()
      end

      def init_folder()
        if configatron.bilancio.attivo
          incassi_pagamenti_bilancio_folder.init_folder
        else
          incassi_pagamenti_folder.init_folder
        end
        norma_liquidazioni_folder.init_folder
      end

      def reset_folder()
        if configatron.bilancio.attivo
          incassi_pagamenti_bilancio_folder.reset_folder
        else
          incassi_pagamenti_folder.reset_folder
        end
        norma_liquidazioni_folder.reset_folder
      end

    end
  end
end
