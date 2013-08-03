# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'

module Views
  module Anagrafica
    module ClientePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui

        model :cliente => {:attrs => []}
        controller :anagrafica

        logger.debug('initializing ClientePanel...')
        xrc = Xrc.instance()
        # Anagrafica cliente
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('chk_no_p_iva', self, :extends => CheckField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_cod_fisc', self, :extends => TextField)
        xrc.find('txt_indirizzo', self, :extends => TextField)
        xrc.find('txt_comune', self, :extends => TextField)
        xrc.find('txt_provincia', self, :extends => TextField)
        xrc.find('txt_cap', self, :extends => TextNumericField)
        xrc.find('txt_citta', self, :extends => TextField)
        xrc.find('txt_cellulare', self, :extends => TextField)
        xrc.find('txt_telefono', self, :extends => TextField)
        xrc.find('txt_fax', self, :extends => TextField)
        xrc.find('txt_e_mail', self, :extends => TextField)
        xrc.find('txt_note', self, :extends => TextField)
        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_new_cliente) do
          reset_panel()
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F3, btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuovo.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_panel()
        reset_cliente_command_state()
      end
      # Gestione eventi
      
      def chk_no_p_iva_click(evt)
        update_ui()
      end
      
      def btn_variazione_click(evt)
        logger.debug("Cliccato sul bottone variazione!")
        begin
          clienti_dlg = Views::Dialog::ClientiDialog.new(self, false)
          clienti_dlg.center_on_screen(Wx::BOTH)
          answer = clienti_dlg.show_modal()
          if answer == Wx::ID_OK
            self.cliente = ctrl.load_cliente(clienti_dlg.selected)
            transfer_cliente_to_view()
            update_ui()
            reset_cliente_command_state()
            txt_denominazione.activate()
          else
            logger.debug("You pressed Cancel")
          end

          clienti_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end
        logger.debug("Cliente: #{self.cliente.inspect}")
      end

      def btn_salva_click(evt)
        logger.debug("Cliccato sul bottone salva!")
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::ANAGRAFICA
                transfer_cliente_from_view()
                if self.cliente.valid?
                  ctrl.save_cliente()
                  evt_chg = Views::Base::CustomEvent::ClienteChangedEvent.new(ctrl.search_clienti())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                  reset_panel()
                  process_event(Views::Base::CustomEvent::BackEvent.new())
                else
                  Wx::message_box(self.cliente.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_cliente_error_field()

                end
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)
          
        rescue Exception => e
          log_error(self, e)
        end
        logger.debug("Cliente: #{self.cliente.inspect}")
        evt.skip()
      end

      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if can? :write, Helpers::ApplicationHelper::Modulo::ANAGRAFICA
              if self.cliente.modificabile?
                res = Wx::message_box("Confermi l'eliminazione del cliente?",
                  'Domanda',
                  Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  Wx::BusyCursor.busy() do
                    ctrl.delete_cliente()
                    evt_chg = Views::Base::CustomEvent::ClienteChangedEvent.new(ctrl.search_clienti())
                    # This sends the event for processing by listeners
                    process_event(evt_chg)
                    reset_panel()
                  end
                end
              else
                Wx::message_box("Il cliente non puo' essere eliminato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            else
              Wx::message_box('Utente non autorizzato.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
            end
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)
          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_nuovo_click(evt)
        logger.debug("Cliccato sul bottone nuovo!")
        reset_panel()
      end

      def reset_panel()
        reset_cliente()
        reset_cliente_command_state()
        txt_p_iva.enable(true)
        chk_attivo.value = true
        txt_denominazione.activate()
      end
			
      def update_ui()
        if chk_no_p_iva.checked?
          txt_p_iva.clear()
          txt_p_iva.enable(false)
        else
          txt_p_iva.enable(true)
        end
      end
      
      def reset_cliente_command_state()
        if cliente.new_record?
          disable_widgets [btn_elimina]
        else
          if self.cliente.modificabile?
            enable_widgets [btn_elimina]
          else
            disable_widgets [btn_elimina]
          end
        end
      end

    end
  end
end