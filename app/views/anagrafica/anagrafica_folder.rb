# encoding: utf-8

require 'app/views/anagrafica/cliente_panel'
require 'app/views/anagrafica/fornitore_panel'

module Views
  module Anagrafica
    module AnagraficaFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing AnagraficaFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('CLIENTE_PANEL', self, :extends => Views::Anagrafica::ClientePanel)
        cliente_panel.ui()
        xrc.find('FORNITORE_PANEL', self, :extends => Views::Anagrafica::FornitorePanel)
        fornitore_panel.ui()

      end
      
      def init_folder()
        cliente_panel.init_panel()
        fornitore_panel.init_panel()
      end
    end
  end
end
