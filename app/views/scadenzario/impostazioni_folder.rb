# encoding: utf-8

require 'app/views/scadenzario/impostazioni_notebook_mgr'

module Views
  module Scadenzario
    module ImpostazioniFolder
      include Views::Base::Folder

      def ui
        logger.debug('initializing Scadenzario ImpostazioniFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('IMPOSTAZIONI_NOTEBOOK_MGR', self, :extends => Views::Scadenzario::ImpostazioniNotebookMgr)
        impostazioni_notebook_mgr.ui()

        map_events(self)
      end

      def init_folder()
        impostazioni_notebook_mgr.init_folder()
      end

    end
  end
end
