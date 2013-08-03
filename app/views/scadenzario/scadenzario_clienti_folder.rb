# encoding: utf-8

require 'app/views/scadenzario/fattura_cliente_panel'

module Views
  module Scadenzario
    module ScadenzarioClientiFolder
      include Views::Base::Folder

      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing ScadenzarioFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('FATTURA_CLIENTE_PANEL', self, :extends => Views::Scadenzario::FatturaClientePanel)
        fattura_cliente_panel.ui(self)

        evt_menu(WX_ID_F2) do
          fattura_cliente_panel.incassi_fattura_cliente_panel.lstrep_incassi_fattura.activate()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F3, fattura_cliente_panel.btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F6, fattura_cliente_panel.btn_cliente.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, fattura_cliente_panel.btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, fattura_cliente_panel.btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, fattura_cliente_panel.btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        fattura_cliente_panel.init_panel()
      end
      
    end
  end
end
