# encoding: utf-8

require 'app/views/prima_nota/categoria_pdc_panel'
require 'app/views/prima_nota/pdc_panel'
require 'app/views/prima_nota/norma_panel'
require 'app/views/prima_nota/interessi_panel'

module Views
  module PrimaNota
    module PdcFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing PdcFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('CATEGORIA_PDC_PANEL', self, :extends => Views::PrimaNota::CategoriaPdcPanel)
        categoria_pdc_panel.ui()
        xrc.find('PDC_PANEL', self, :extends => Views::PrimaNota::PdcPanel)
        pdc_panel.ui()
        xrc.find('NORMA_PANEL', self, :extends => Views::PrimaNota::NormaPanel)
        norma_panel.ui()
        xrc.find('INTERESSI_PANEL', self, :extends => Views::PrimaNota::InteressiPanel)
        interessi_panel.ui()

      end

      def init_folder()
        categoria_pdc_panel.init_panel()
        pdc_panel.init_panel()
        norma_panel.init_panel()
        interessi_panel.init_panel()
      end
      
    end
  end
end
