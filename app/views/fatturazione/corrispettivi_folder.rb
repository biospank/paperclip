# encoding: utf-8

require 'app/views/fatturazione/corrispettivi_panel'

module Views
  module Fatturazione
    module CorrispettiviFolder
      include Views::Base::Folder

      WX_ID_F2 = Wx::ID_ANY

      def ui
        logger.debug('initializing CorrispettiviFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('CORRISPETTIVI_PANEL', self, :extends => Views::Fatturazione::CorrispettiviPanel)
        corrispettivi_panel.ui(self)

        evt_menu(WX_ID_F2) do
          corrispettivi_panel.righe_corrispettivi_panel.lstrep_righe_corrispettivi.activate()
        end
         # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, corrispettivi_panel.btn_salva.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_folder()
        corrispettivi_panel.init_panel()
      end
      
    end
  end
end
