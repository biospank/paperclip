# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Configurazione
    module AccountPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      include Helpers::ZipHelper
      
      def ui

        model :utente => {:attrs => [:password]}
        controller :configurazione

        logger.debug('initializing AccountPanel...')
        xrc = Xrc.instance()

        xrc.find('btn_backup', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      def init_panel()

      end

      def reset_panel()
        
      end

      # Gestione eventi
      
      def btn_backup_click(evt)
        begin
          bra_db, filename, filetype = nil
          if configatron.connection.mode == :remote
            Wx::BusyCursor.busy() do
              Wx::BusyInfo.busy("Backup del database remoto: attendere...", self) do
                ctrl.dump()
                bra_db = File.join('db/backup', Models::Azienda.current.dati_azienda.denominazione.strip + '_' + Time.now.strftime("%d_%m_%Y_%H_%M_%S") + '.backup.zip')
                filename = Models::Azienda.current.dati_azienda.denominazione.strip + '_' + Time.now.strftime("%d_%m_%Y_%H_%M_%S") + '.zip'
                filetype = "*.zip"
                create_archive(bra_db, 'db/schema.rb', 'db/data.yml', 'conf/paperclip.yml', 'db/production/bra.db')
              end
            end
          else
            if configatron.env == 'production'
              bra_db = 'db/production/bra.db'
            else
              bra_db = 'db/development/bra.db'
            end
            filename = Models::Azienda.current.dati_azienda.denominazione.strip + '_' + Time.now.strftime("%d_%m_%Y_%H_%M_%S") + '.backup'
            filetype = "*.backup"
            #create_archive(bra_db, 'conf/paperclip.yml', 'db/production/bra.db')
          end
          dlg = Wx::FileDialog.new(self, "Salva con nome...", Dir.getwd(), filename, filetype, Wx::SAVE)
#          dlg.set_filter_index(2)
          if dlg.show_modal() == Wx::ID_OK
            Wx::BusyCursor.busy() do
              path = dlg.get_path()
              logger.debug("You selected " + path)
              logger.debug("CWD: " + Dir.getwd())
              logger.debug("bra_db: " + bra_db)
              FileUtils.cp bra_db, path
            end
          end
        rescue Exception => e
          log_error(self, e)
        end
        evt.skip()
      end

    end
  end
end