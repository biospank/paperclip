# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/norma_dialog'

module Views
  module PrimaNota
    module NormaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui()

        model :norma => {:attrs => [:codice, :percentuale, :descrizione, :attiva]}

        controller :prima_nota

        logger.debug('initializing NormaPanel...')
        xrc = Xrc.instance()
        # NotaSpese

        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_percentuale', self, :extends => DecimalField)
        xrc.find('chk_attiva', self, :extends => CheckField)
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

        subscribe(:evt_new_norma) do
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
          reset_norma()

          reset_norma_command_state()

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
            if norma = ctrl.load_norma_by_codice(txt_codice.view_data)
              self.norma = norma
              transfer_norma_to_view()
              reset_norma_command_state()
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

      def btn_variazione_click(evt)
        begin
          # se esiste ricerca solo le occorrenze associate ad un cliente
          transfer_norma_from_view()
          norma_dlg = Views::Dialog::NormaDialog.new(self, false)
          norma_dlg.center_on_screen(Wx::BOTH)
          if norma_dlg.show_modal() == Wx::ID_OK
            self.norma = ctrl.load_norma(norma_dlg.selected)
            transfer_norma_to_view()
            reset_norma_command_state()
            txt_codice.activate()
          else
            logger.debug("You pressed Cancel")
          end

          norma_dlg.destroy()

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
                transfer_norma_from_view()
                if self.norma.valid?
                  ctrl.save_norma()
                  evt_chg = Views::Base::CustomEvent::NormaChangedEvent.new(ctrl.search_norma())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                  reset_panel()
                  process_event(Views::Base::CustomEvent::BackEvent.new())
                else
                  Wx::message_box(self.norma.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_norma_error_field()

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
            if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
              res = Wx::message_box("Confermi l'eliminazione?",
                'Domanda',
                  Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              if res == Wx::YES
                Wx::BusyCursor.busy() do
                  ctrl.delete_norma()
                  evt_chg = Views::Base::CustomEvent::NormataChangedEvent.new(ctrl.search_norma())
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

      def reset_norma_command_state()
        if norma.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_percentuale, txt_descrizione]
        else
          if norma.modificabile?
            enable_widgets [txt_codice, txt_percentuale, txt_descrizione, btn_elimina]
          else
            disable_widgets [txt_codice, txt_percentuale, txt_descrizione, btn_elimina]
          end
        end
      end

    end
  end
end