# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Configurazione
    module ConnessioneRemotaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      include Models
      
      def ui

        model :db_server => {:attrs => [:adapter, 
                                       :host,
                                       :port,
                                       :database,
                                       :username,
                                       :password,
                                       :encoding]}
        controller :configurazione

        logger.debug('initializing ConnessioneRemotaPanel...')
        xrc = Xrc.instance()

        xrc.find('chce_adapter', self, :extends => ChoiceStringField) do |field|
            field.load_data(['postgresql', 'mysql'],
          :include_blank => {:label => ''},
          :select => :first)
          
        end
        xrc.find('txt_host', self, :extends => TextField)
        xrc.find('txt_port', self, :extends => NumericField)
        xrc.find('txt_username', self, :extends => TextField)
        xrc.find('txt_database', self, :extends => TextField)
        xrc.find('txt_password', self, :extends => TextField)
        xrc.find('chce_encoding', self, :extends => ChoiceStringField) do |field|
            field.load_data(['utf-8'],
          :select => :first)
        end

        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)

        map_events(self)
        
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ]
        ]                            
        self.accelerator_table = acc_table  
        
        update_ui()
      end

      def init_panel()

      end

      # Gestione eventi
      
      def btn_salva_click(evt)
        begin
          Wx::BusyCursor.busy() do
            transfer_db_server_from_view()
            if db_server.valid?
              ctrl.save_db_server()
              Wx::message_box('Salvataggio avvenuto correttamente.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              update_ui()
            else
              Wx::message_box(self.db_server.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_db_server_error_field()

            end
          end
        rescue Exception => e
          log_error(self, e)
        end
        evt.skip()
      end

      def btn_elimina_click(evt)
        begin
          Wx::BusyCursor.busy() do
            DbServer.first.destroy
            update_ui()
          end
        rescue Exception => e
          log_error(self, e)
        end
        evt.skip()
      end

      def update_ui()
        self.db_server = (DbServer.first || DbServer.new)
        if db_server.new_record?
          disable_widgets [btn_elimina]
        else
          enable_widgets [btn_elimina]
        end
        transfer_db_server_to_view()
      end
      
    end
  end
end