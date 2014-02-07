# encoding: utf-8

require 'app/views/scadenzario/norma_panel'
require 'app/views/scadenzario/interessi_panel'

module Views
  module Scadenzario
    module NormaLiquidazioniFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing Scadenzario NormaLiquidazioniFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('NORMA_PANEL', self, :extends => Views::Scadenzario::NormaPanel)
        norma_panel.ui()
        xrc.find('INTERESSI_PANEL', self, :extends => Views::Scadenzario::InteressiPanel)
        interessi_panel.ui()

      end

      def init_folder()
        norma_panel.init_panel()
        interessi_panel.init_panel()
      end
      
    end
  end
end
