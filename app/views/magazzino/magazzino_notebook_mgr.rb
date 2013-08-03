# encoding: utf-8

require 'app/helpers/magazzino_helper'
require 'app/views/magazzino/ordine_folder'
require 'app/views/magazzino/impostazioni_folder'
require 'app/views/magazzino/carico_folder'
require 'app/views/magazzino/scarico_folder'
require 'app/views/magazzino/report_folder'

module Views
  module Magazzino
    module MagazzinoNotebookMgr
      include Views::Base::View
      include Helpers::MVCHelper

      def ui
        controller :base
        logger.debug('initializing MagazzinoNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('ORDINE_FOLDER', self, :extends => Views::Magazzino::OrdineFolder)
        ordine_folder.ui()
        xrc.find('IMPOSTAZIONI_FOLDER', self, :extends => Views::Magazzino::ImpostazioniFolder)
        impostazioni_folder.ui()
        xrc.find('CARICO_FOLDER', self, :extends => Views::Magazzino::CaricoFolder)
        carico_folder.ui()
        xrc.find('SCARICO_FOLDER', self, :extends => Views::Magazzino::ScaricoFolder)
        scarico_folder.ui()
        xrc.find('REPORT_FOLDER', self, :extends => Views::Magazzino::ReportFolder)
        report_folder.ui()
      end
      
      def magazzino_notebook_mgr_page_changing(evt)
        logger.debug("page changing!")
        if ctrl.locked?
          Wx::message_box("Completare la chiusura dei movimenti in sospeso oppure,\npremere il pulsante indietro.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          evt.veto() 
        end
        #evt.skip()
      end

      def magazzino_notebook_mgr_page_changed(evt)
        logger.debug("page changed!")
        case evt.selection
        when Helpers::MagazzinoHelper::WXBRA_ORDINE_FOLDER
          ordine_folder().init_folder()
        when Helpers::MagazzinoHelper::WXBRA_IMPOSTAZIONI_FOLDER
          impostazioni_folder().init_folder()
        when Helpers::MagazzinoHelper::WXBRA_CARICO_FOLDER
          carico_folder().init_folder()
        when Helpers::MagazzinoHelper::WXBRA_SCARICO_FOLDER
          scarico_folder().init_folder()
        when Helpers::MagazzinoHelper::WXBRA_REPORT_FOLDER
          report_folder().init_folder()
          
        end
        evt.skip()
      end
    
    end
  end
end
