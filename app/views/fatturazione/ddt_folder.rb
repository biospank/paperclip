# encoding: utf-8

require 'app/views/fatturazione/ddt_panel'

module Views
  module Fatturazione
    module DdtFolder
      include Views::Base::Folder

      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing DdtFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('DDT_PANEL', self, :extends => Views::Fatturazione::DdtPanel)
        ddt_panel.ui(self)

        evt_menu(WX_ID_F2) do
          ddt_panel.righe_ddt_panel.lstrep_righe_ddt.activate()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F3, ddt_panel.btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F6, ddt_panel.btn_cliente.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F7, ddt_panel.btn_fornitore.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, ddt_panel.btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, ddt_panel.btn_stampa.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, ddt_panel.btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, ddt_panel.btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        ddt_panel.init_panel()
      end
      
    end
  end
end
