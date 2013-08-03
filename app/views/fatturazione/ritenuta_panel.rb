# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/ritenute_dialog'

module Views
  module Fatturazione
    module RitenutaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui()

        model :ritenuta => {:attrs => [:codice, :percentuale, :descrizione, :attiva, :predefinita]}
        
        controller :fatturazione

        logger.debug('initializing RitenutaPanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_percentuale', self, :extends => DecimalField)
        xrc.find('chk_attiva', self, :extends => CheckField)
        xrc.find('chk_predefinita', self, :extends => CheckField)
        xrc.find('txt_descrizione', self, :extends => TextField)
        
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuova', self)

        disable_widgets [btn_elimina]

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_new_ritenuta) do
          reset_panel()
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F3, btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuova.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end
      
      def reset_panel()
        begin
          reset_ritenuta()
          
          reset_ritenuta_command_state()

          txt_codice.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def txt_codice_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if ritenuta = ctrl.load_ritenuta_by_codice(txt_codice.view_data)
              self.ritenuta = ritenuta
              transfer_ritenuta_to_view()
              update_ui()
              reset_ritenuta_command_state()
            end
            evt.skip()
          when Wx::K_F5
            btn_variazione_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def chk_attiva_click(evt)
        update_ui()
      end
      
      def btn_variazione_click(evt)
        begin
          transfer_ritenuta_from_view()
          ritenute_dlg = Views::Dialog::RitenuteDialog.new(self, false)
          ritenute_dlg.center_on_screen(Wx::BOTH)
          if ritenute_dlg.show_modal() == Wx::ID_OK
            self.ritenuta = ctrl.load_ritenuta(ritenute_dlg.selected)
            transfer_ritenuta_to_view()
            
            disable_widgets [
            ]
            
            reset_ritenuta_command_state()
            txt_codice.activate()
            
          else
            logger.debug("You pressed Cancel")
          end

          ritenute_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                transfer_ritenuta_from_view()
                if self.ritenuta.valid?
                  ctrl.save_ritenuta()
                  evt_chg = Views::Base::CustomEvent::RitenutaChangedEvent.new(ctrl.search_ritenute())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                  reset_panel()
                  process_event(Views::Base::CustomEvent::BackEvent.new())
                else
                  Wx::message_box(self.ritenuta.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_ritenuta_error_field()

                end
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
              res = Wx::message_box("Confermi l'eliminazione della ritenuta?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              if res == Wx::YES
                Wx::BusyCursor.busy() do
                  ctrl.delete_ritenuta()
                  evt_chg = Views::Base::CustomEvent::RitenutaChangedEvent.new(ctrl.search_ritenute())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  reset_panel()
                end
              end

            else
              Wx::message_box('Utente non autorizzato.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
            end
          txt_codice.activate()
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
      
      def btn_nuova_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def reset_ritenuta_command_state()
        if ritenuta.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_percentuale, txt_descrizione]
        else
          if ritenuta.modificabile?
            enable_widgets [txt_codice, txt_percentuale, txt_descrizione, btn_elimina]
          else
            disable_widgets [txt_codice, txt_percentuale, txt_descrizione, btn_elimina]
          end
        end
      end

      def update_ui()
        if chk_attiva.checked?
          enable_widgets [chk_predefinita]
        else
          chk_predefinita.view_data = false
          disable_widgets [chk_predefinita]
        end
      end

    end
  end
end