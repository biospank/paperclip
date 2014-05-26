# encoding: utf-8

require 'app/views/prima_nota/causali_bilancio_panel'

module Views
  module PrimaNota
    module CausaliBilancioFolder
      include Views::Base::Folder

      def ui
        logger.debug('initializing CausaliBilancioFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('CAUSALI_BILANCIO_PANEL', self, :extends => Views::PrimaNota::CausaliBilancioPanel)
        causali_bilancio_panel.ui()

      end

      def init_folder()
        causali_bilancio_panel.init_panel()
      end

    end
  end
end
