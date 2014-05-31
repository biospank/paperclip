# encoding: utf-8

require 'app/views/magazzino/magazzino_panel'
require 'app/views/magazzino/prodotto_panel'
require 'app/views/magazzino/aliquota_prodotti_panel'

module Views
  module Magazzino
    module ImpostazioniFolder
      include Views::Base::Folder

      def ui
        logger.debug('initializing Magazzino ProdottoPanel...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('MAGAZZINO_PANEL', self, :extends => Views::Magazzino::MagazzinoPanel)
        magazzino_panel.ui()
        xrc.find('PRODOTTO_PANEL', self, :extends => Views::Magazzino::ProdottoPanel)
        prodotto_panel.ui()
        xrc.find('ALIQUOTA_PRODOTTI_PANEL', self, :extends => Views::Magazzino::AliquotaProdottiPanel)
        aliquota_prodotti_panel.ui()

      end

      def init_folder()
        prodotto_panel.init_panel()
      end

    end
  end
end
