# encoding: utf-8

require 'app/views/configurazione/connessione_remota_panel'
require 'app/views/configurazione/dump_panel'

module Views
  module Configurazione
    module DatabaseFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing DatabaseFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('CONNESSIONE_REMOTA_PANEL', self, :extends => Views::Configurazione::ConnessioneRemotaPanel)
        connessione_remota_panel.ui()
        xrc.find('DUMP_PANEL', self, :extends => Views::Configurazione::DumpPanel)
        dump_panel.ui()

      end

      def init_folder()
        connessione_remota_panel.init_panel()
        dump_panel.init_panel()
      end
      
    end
  end
end
