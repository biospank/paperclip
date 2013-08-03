# encoding: utf-8

require 'app/helpers/configurazione_helper'
require 'app/views/configurazione/azienda_folder'
require 'app/views/configurazione/progressivi_folder'
require 'app/views/configurazione/database_folder'
require 'app/views/configurazione/utenti_folder'

module Views
  module Configurazione
    module ConfigurazioneNotebookMgr
      include Views::Base::View
      
      def ui
        logger.debug('initializing ConfigurazioneNotebookMgr...')
        xrc = Helpers::WxHelper::Xrc.instance()
        xrc.find('AZIENDA_FOLDER', self, :extends => Views::Configurazione::AziendaFolder)
        azienda_folder.ui()
        xrc.find('PROGRESSIVI_FOLDER', self, :extends => Views::Configurazione::ProgressiviFolder)
        progressivi_folder.ui()
        xrc.find('DATABASE_FOLDER', self, :extends => Views::Configurazione::DatabaseFolder)
        database_folder.ui()
        xrc.find('UTENTI_FOLDER', self, :extends => Views::Configurazione::UtentiFolder)
        utenti_folder.ui()

      end

      def configurazione_notebook_mgr_page_changing(evt)
        evt.skip()
      end

      def configurazione_notebook_mgr_page_changed(evt)
        case evt.selection
        when Helpers::ConfigurazioneHelper::WXBRA_AZIENDA_FOLDER
          azienda_folder().init_folder()
        when Helpers::ConfigurazioneHelper::WXBRA_PROGRESSIVI_FOLDER
          progressivi_folder().init_folder()
        when Helpers::ConfigurazioneHelper::WXBRA_DATABASE_FOLDER
          database_folder().init_folder()
          if Models::Utente.system?
            database_folder.enable()
          else
            database_folder.enable(false)
          end
        when Helpers::ConfigurazioneHelper::WXBRA_UTENTI_FOLDER
          utenti_folder().init_folder()
        end
        evt.skip()
      end
    
    end
  end
end
