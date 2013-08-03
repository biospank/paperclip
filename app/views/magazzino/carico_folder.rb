# encoding: utf-8

require 'app/views/magazzino/carico_panel'

module Views
  module Magazzino
    module CaricoFolder
      include Views::Base::Folder

      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing CaricoFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('CARICO_PANEL', self, :extends => Views::Magazzino::CaricoPanel)
        carico_panel.ui(self)

        evt_menu(WX_ID_F2) do
          carico_panel.righe_carico_panel.lstrep_righe_carico.activate()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, carico_panel.btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, carico_panel.btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        carico_panel.init_panel()
      end
      
    end
  end
end
