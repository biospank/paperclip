# encoding: utf-8

require 'app/views/prima_nota/causali_panel'

module Views
  module PrimaNota
    module CausaliFolder
      include Views::Base::Folder
      
      def ui
        logger.debug('initializing CausaliFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('CAUSALI_PANEL', self, :extends => Views::PrimaNota::CausaliPanel)
        causali_panel.ui()

      end

      def init_folder()
        causali_panel.init_panel()
      end
      
#      def banche
#        owner.banche
#      end
    end
  end
end
