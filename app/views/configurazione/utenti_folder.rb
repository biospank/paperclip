# encoding: utf-8

require 'app/views/configurazione/utenti_panel'

module Views
  module Configurazione
    module UtentiFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing UtentiFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('UTENTI_PANEL', self, :extends => Views::Configurazione::UtentiPanel)
        utenti_panel.ui()

      end

      def init_folder()
        utenti_panel.init_panel()
      end
      
    end
  end
end
