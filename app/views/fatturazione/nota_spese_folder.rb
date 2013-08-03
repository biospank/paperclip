# encoding: utf-8

require 'app/views/fatturazione/ns_fattura_panel'

module Views
  module Fatturazione
    module NotaSpeseFolder
      include Views::Base::Folder

      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing NotaSpesePanel...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('NS_FATTURA_PANEL', self, :extends => Views::Fatturazione::NSFatturaPanel)
        ns_fattura_panel.ui(self)
        
        evt_menu(WX_ID_F2) do
          ns_fattura_panel.ns_righe_fattura_panel.lstrep_righe_nota_spese.activate()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F3, ns_fattura_panel.btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F6, ns_fattura_panel.btn_cliente.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, ns_fattura_panel.btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, ns_fattura_panel.btn_stampa.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, ns_fattura_panel.btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, ns_fattura_panel.btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        ns_fattura_panel.init_panel()
      end
      
    end
  end
end
