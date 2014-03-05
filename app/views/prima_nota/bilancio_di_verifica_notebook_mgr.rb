# encoding: utf-8

require 'app/helpers/prima_nota_helper'
require 'app/views/prima_nota/stato_patrimoniale_folder'
require 'app/views/prima_nota/conto_economico_folder'

module Views
  module PrimaNota
    module BilancioDiVerificaNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper
      
      def ui
        
        logger.debug('initializing Bilancio BilancioDiVerificaNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('STATO_PATRIMONIALE_FOLDER', self, :extends => Views::PrimaNota::StatoPatrimonialeFolder)
        stato_patrimoniale_folder.ui()
        xrc.find('CONTO_ECONOMICO_FOLDER', self, :extends => Views::PrimaNota::ContoEconomicoFolder)
        conto_economico_folder.ui()
        
      end

      def bilancio_di_verifica_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def bilancio_di_verifica_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::PrimaNotaHelper::WXBRA_STATO_PATRIMONIALE_FOLDER
          stato_patrimoniale_folder().init_folder()
        when Helpers::PrimaNotaHelper::WXBRA_CONTO_ECONOMICO_FOLDER
          conto_economico_folder().init_folder()
          
        end
        evt.skip()
      end

      def init_folders()
        
      end
    end
  end
end
