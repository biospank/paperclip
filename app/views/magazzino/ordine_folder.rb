# encoding: utf-8

require 'app/views/magazzino/ordine_panel'

module Views
  module Magazzino
    module OrdineFolder
      include Views::Base::Folder

      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing OrdineFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('ORDINE_PANEL', self, :extends => Views::Magazzino::OrdinePanel)
        ordine_panel.ui(self)

        evt_menu(WX_ID_F2) do
          ordine_panel.righe_ordine_panel.lstrep_righe_ordine.activate()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F3, ordine_panel.btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F7, ordine_panel.btn_fornitore.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, ordine_panel.btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, ordine_panel.btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, ordine_panel.btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        ordine_panel.init_panel()
      end
      
    end
  end
end
