# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Configurazione
    module DumpPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui

        controller :configurazione

        logger.debug('initializing DumpPanel...')
        xrc = Xrc.instance()

        xrc.find('chce_database_mode', self, :extends => ChoiceStringField) do |field|
            field.load_data(['locale', 'remoto'],
          :select => :first)

        end

        xrc.find('btn_dump', self)
        xrc.find('btn_restore', self)

        map_events(self)
        
      end

      def init_panel()
        case configatron.connection.mode
        when :local
          chce_database_mode.select_first()
        when :remote
          chce_database_mode.select_last()
        end
      end

      # Gestione eventi
      
      def chce_database_mode_select(evt)
        begin
          case chce_database_mode.view_data.to_sym
          when :locale
            logger.info("Connecting to local host...")
            Wx::BusyCursor.busy() do
              PaperclipConfig::Db.connect_local()
              configatron.connection.mode = :local
              process_event(Views::Base::CustomEvent::ConfigChangedEvent.new('local'))
              # TODO
              # lanciare l'evento per scrivere il file
              # di configurazione e visualizzare il msg
              # sulla status bar
              # catturato da main_frame
            end
          when :remoto
            db_server = ctrl.load_db_server()
            logger.info("Connecting to remote host: #{db_server.host}...")
            Wx::BusyCursor.busy() do
              PaperclipConfig::Db.connect_remote(db_server)
              configatron.connection.mode = :remote
              process_event(Views::Base::CustomEvent::ConfigChangedEvent.new(db_server.host))
              # TODO
              # lanciare l'evento per scrivere il file
              # di configurazione e visualizzare il msg
              # sulla status bar
              # catturato da main_frame
            end
          end
        rescue Exception => e
          PaperclipConfig::Db.connect_local()
          chce_database_mode.select_first()
          configatron.connection.mode = :local
          process_event(Views::Base::CustomEvent::ConfigChangedEvent.new('local'))
            # TODO
            # lanciare l'evento per scrivere il file
            # di configurazione e visualizzare il msg
            # sulla status bar
            # catturato da main_frame
          log_error(self, e)
        end

      end
      
      def btn_dump_click(evt)
        begin
          case chce_database_mode.view_data.to_sym
          when :locale
            Wx::BusyCursor.busy() do
              Wx::BusyInfo.busy("Dump del database locale: attendere...", self) do
                ctrl.dump()
                Wx::message_box("Operazione completata: \n**** Convertire il file schema.rb in minuscolo ****\n**** Ipostare numero connessioni ****",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
             end
            end
          when :remoto
            Wx::BusyCursor.busy() do
              Wx::BusyInfo.busy("Dump del database remoto: attendere...", self) do
                ctrl.dump()
                Wx::message_box('Operazione completata.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
          end
        rescue Exception => e
          PaperclipConfig::Db.connect_local()
          chce_database_mode.select_first()
          configatron.connection.mode = :local
          process_event(Views::Base::CustomEvent::ConfigChangedEvent.new('local'))
            # TODO
            # lanciare l'evento per scrivere il file
            # di configurazione e visualizzare il msg
            # sulla status bar
            # catturato da main_frame
          log_error(self, e)
        end
      end

      def btn_restore_click(evt)
        begin
          case chce_database_mode.view_data.to_sym
          when :locale
            Wx::BusyCursor.busy() do
              Wx::BusyInfo.busy("Restore del database locale: attendere...", self) do
                ctrl.restore()
                Wx::message_box('Operazione completata.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
          when :remoto
            Wx::BusyCursor.busy() do
              Wx::BusyInfo.busy("Restore del database remoto: attendere...", self) do
                ctrl.restore()
                Wx::message_box('Operazione completata.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
          end
        rescue Exception => e
          PaperclipConfig::Db.connect_local()
          chce_database_mode.select_first()
          configatron.connection.mode = :local
          process_event(Views::Base::CustomEvent::ConfigChangedEvent.new('local'))
            # TODO
            # lanciare l'evento per scrivere il file
            # di configurazione e visualizzare il msg
            # sulla status bar
            # catturato da main_frame
          log_error(self, e)
        end
      end

    end
  end
end