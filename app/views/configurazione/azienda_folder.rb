# encoding: utf-8

require 'app/views/configurazione/dati_azienda_panel'
require 'app/views/configurazione/banca_panel'
require 'app/views/configurazione/account_panel'

module Views
  module Configurazione
    module AziendaFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing AziendaFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('DATI_AZIENDA_PANEL', self, :extends => Views::Configurazione::DatiAziendaPanel)
        dati_azienda_panel.ui()
        xrc.find('BANCA_PANEL', self, :extends => Views::Configurazione::BancaPanel)
        banca_panel.ui()
        xrc.find('ACCOUNT_PANEL', self, :extends => Views::Configurazione::AccountPanel)
        account_panel.ui()

      end

      def init_folder()
        dati_azienda_panel.init_panel()
#        banca_panel.init_panel()
      end
      
    end
  end
end
