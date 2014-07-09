# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/incassi_ricorrenti_dialog'

module Views
  module Fatturazione
    module IncassoRicorrentePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui()

        model :cliente => {:attrs => [:denominazione]},
          :incasso_ricorrente => {:attrs => [:importo, :descrizione, :attivo, :predefinito]}
        
        controller :fatturazione

        logger.debug('initializing IncassoRicorrentePanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_importo', self, :extends => DecimalField)
        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('txt_descrizione', self, :extends => TextField)
        
        xrc.find('btn_cliente', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        disable_widgets [btn_elimina]

        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_new_incasso_ricorrente) do
          reset_panel()
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F3, btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F6, btn_cliente.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuovo.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end
      
      def reset_panel()
        begin
          reset_cliente()
          reset_incasso_ricorrente()
          
          reset_incasso_ricorrente_command_state()

          txt_importo.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def btn_cliente_click(evt)
        begin
          clienti_dlg = Views::Dialog::ClientiDialog.new(self)
          clienti_dlg.center_on_screen(Wx::BOTH)
          answer = clienti_dlg.show_modal()
          if answer == Wx::ID_OK
            reset_panel()
            self.cliente = ctrl.load_cliente(clienti_dlg.selected)
            self.incasso_ricorrente.cliente = self.cliente
            transfer_cliente_to_view()
            txt_importo.activate()
          elsif answer == clienti_dlg.btn_nuovo.get_id
            evt_new = Views::Base::CustomEvent::NewEvent.new(:cliente, [Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW, Helpers::FatturazioneHelper::WXBRA_IMPOSTAZIONI_FOLDER])
            # This sends the event for processing by listeners
            process_event(evt_new)
          else
            logger.debug("You pressed Cancel")
          end

          clienti_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end
        
        evt.skip()
      end

      def btn_variazione_click(evt)
        begin
          # se esiste ricerca solo le occorrenze associate ad un cliente
          transfer_incasso_ricorrente_from_view()
          incassi_ricorrenti_dlg = Views::Dialog::IncassiRicorrentiDialog.new(self, false)
          incassi_ricorrenti_dlg.center_on_screen(Wx::BOTH)
          if incassi_ricorrenti_dlg.show_modal() == Wx::ID_OK
            self.incasso_ricorrente = ctrl.load_incasso_ricorrente(incassi_ricorrenti_dlg.selected)
            self.cliente = self.incasso_ricorrente.cliente
            transfer_cliente_to_view()
            transfer_incasso_ricorrente_to_view()
            reset_incasso_ricorrente_command_state()
            txt_importo.activate()

          else
            logger.debug("You pressed Cancel")
          end

          incassi_ricorrenti_dlg.destroy()
          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                  transfer_cliente_from_view()
                  if cliente?
                    transfer_incasso_ricorrente_from_view()
                    if self.incasso_ricorrente.valid?
                      ctrl.save_incasso_ricorrente()
                      Wx::message_box('Salvataggio avvenuto correttamente.',
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)
                      reset_panel()
                      process_event(Views::Base::CustomEvent::BackEvent.new())
                    else
                      Wx::message_box(self.incasso_ricorrente.error_msg,
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      focus_incasso_ricorrente_error_field()

                    end
                  end
                else
                  Wx::message_box('Utente non autorizzato.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
              else
                Wx::message_box("Licenza scaduta il #{ctrl.licenza.data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
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

        evt.skip()
      end
      
      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if ctrl.licenza.attiva?
              if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                res = Wx::message_box("Confermi l'eliminazione dell'incasso ricorrente?",
                  'Domanda',
                    Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  Wx::BusyCursor.busy() do
                    ctrl.delete_incasso_ricorrente()
                    reset_panel()
                  end
                end
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            else
              Wx::message_box("Licenza scaduta il #{ctrl.licenza.data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
            end
            txt_importo.activate()
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
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def reset_incasso_ricorrente_command_state()
        if incasso_ricorrente.new_record?
          disable_widgets [btn_elimina]
        else
          enable_widgets [btn_elimina]
        end
      end

      def cliente?
        if self.cliente.new_record?
          Wx::message_box('Selezionare un cliente',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
            
          btn_cliente.set_focus()
          return false
        else
          return true
        end

      end


    end
  end
end