# encoding: utf-8

require 'app/views/magazzino/scarico_panel'

module Views
  module Magazzino
    module ScaricoFolder
      include Views::Base::Folder

      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing ScaricoFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('SCARICO_PANEL', self, :extends => Views::Magazzino::ScaricoPanel)
        scarico_panel.ui(self)

        evt_menu(WX_ID_F2) do
          scarico_panel.righe_scarico_panel.lstrep_righe_scarico.activate()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F7, scarico_panel.btn_cliente.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, scarico_panel.btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, scarico_panel.btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        scarico_panel.init_panel()
      end
      
    end
  end
end
