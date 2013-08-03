# encoding: utf-8

require 'app/views/scadenzario/fattura_fornitore_panel'

module Views
  module Scadenzario
    module ScadenzarioFornitoriFolder
      include Views::Base::Folder
      
      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing ScadenzarioFornitoriFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('FATTURA_FORNITORE_PANEL', self, :extends => Views::Scadenzario::FatturaFornitorePanel)
        fattura_fornitore_panel.ui(self)

        evt_menu(WX_ID_F2) do
          fattura_fornitore_panel.pagamenti_fattura_fornitore_panel.lstrep_pagamenti_fattura.activate()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F3, fattura_fornitore_panel.btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F7, fattura_fornitore_panel.btn_fornitore.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, fattura_fornitore_panel.btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, fattura_fornitore_panel.btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, fattura_fornitore_panel.btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        fattura_fornitore_panel.init_panel()
      end
      
    end
  end
end
