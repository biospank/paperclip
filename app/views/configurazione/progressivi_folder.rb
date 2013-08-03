# encoding: utf-8

require 'app/views/configurazione/progressivo_fattura_panel'
require 'app/views/configurazione/progressivo_ns_panel'
require 'app/views/configurazione/progressivo_nc_panel'
require 'app/views/configurazione/progressivo_ddt_panel'

module Views
  module Configurazione
    module ProgressiviFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing ProgressiviFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('PROGRESSIVO_FATTURA_PANEL', self, :extends => Views::Configurazione::ProgressivoFatturaPanel)
        progressivo_fattura_panel.ui()
        xrc.find('PROGRESSIVO_NS_PANEL', self, :extends => Views::Configurazione::ProgressivoNotaSpesePanel)
        progressivo_ns_panel.ui()
        xrc.find('PROGRESSIVO_NC_PANEL', self, :extends => Views::Configurazione::ProgressivoNotaDiCreditoPanel)
        progressivo_nc_panel.ui()
        xrc.find('PROGRESSIVO_DDT_PANEL', self, :extends => Views::Configurazione::ProgressivoDdtPanel)
        progressivo_ddt_panel.ui()

      end

    end
  end
end
