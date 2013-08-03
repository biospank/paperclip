# encoding: utf-8

require 'app/views/fatturazione/aliquota_panel'
require 'app/views/fatturazione/ritenuta_panel'
require 'app/views/fatturazione/incasso_ricorrente_panel'

module Views
  module Fatturazione
    module ImpostazioniFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing ImopstazioniPanel...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('ALIQUOTA_PANEL', self, :extends => Views::Fatturazione::AliquotaPanel)
        aliquota_panel.ui()
        xrc.find('RITENUTA_PANEL', self, :extends => Views::Fatturazione::RitenutaPanel)
        ritenuta_panel.ui()
        xrc.find('INCASSO_RICORRENTE_PANEL', self, :extends => Views::Fatturazione::IncassoRicorrentePanel)
        incasso_ricorrente_panel.ui()

      end

      def init_folder()
        aliquota_panel.init_panel()
        ritenuta_panel.init_panel()
        incasso_ricorrente_panel.init_panel()
      end
      
    end
  end
end
