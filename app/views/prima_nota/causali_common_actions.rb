# encoding: utf-8

module Views
  module PrimaNota
    module CausaliCommonActions
      include Views::Base::Panel
      include Helpers::MVCHelper

      def init_panel()
        reset_causale_command_state()

        txt_codice.activate()

      end

      def reset_panel()
        begin
          reset_causale()

          reset_causale_command_state()

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
            if causale = ctrl.load_causale_by_codice(txt_codice.view_data)
              self.causale = causale
              transfer_causale_to_view()
              update_ui()
              reset_causale_command_state()
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
          transfer_causale_from_view()
          causali_dlg = Views::Dialog::CausaliDialog.new(self, false)
          causali_dlg.center_on_screen(Wx::BOTH)
          if causali_dlg.show_modal() == Wx::ID_OK
            self.causale = ctrl.load_causale(causali_dlg.selected)
            transfer_causale_to_view()
            update_ui()
            reset_causale_command_state()
            txt_codice.activate() if txt_codice.enabled?

          else
            logger.debug("You pressed Cancel")
          end

          causali_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
                transfer_causale_from_view()
                if self.causale.valid?
                  ctrl.save_causale()
                  evt_chg = Views::Base::CustomEvent::CausaleChangedEvent.new(ctrl.search_causali())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                  reset_panel()
                  process_event(Views::Base::CustomEvent::BackEvent.new())
                else
                  Wx::message_box(self.causale.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_causale_error_field()

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

        evt.skip()
      end

      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
              res = Wx::message_box("Confermi l'eliminazione della causale?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              if res == Wx::YES
                Wx::BusyCursor.busy() do
                  ctrl.delete_causale()
                  evt_chg = Views::Base::CustomEvent::CausaleChangedEvent.new(ctrl.search_causali())
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
