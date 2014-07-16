# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/magazzini_dialog'

module Views
  module Magazzino
    module MagazzinoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      def ui()

        model :magazzino => {:attrs => [:nome,
                                       :descrizione,
                                       :attivo,
                                       :predefinito]}

        controller :magazzino

        logger.debug('initializing MagazzinoPanel...')
        xrc = Xrc.instance()
        # NotaSpese

        xrc.find('txt_nome', self, :extends => TextField)
        xrc.find('txt_descrizione', self, :extends => TextField)
        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('chk_predefinito', self, :extends => CheckField)

        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        disable_widgets [btn_elimina]

        map_events(self)

        subscribe(:evt_azienda_changed) do
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
        reset_magazzino()

        reset_magazzino_command_state()

        txt_nome.activate()

      end

      def reset_panel()
        begin
          reset_magazzino()

          reset_magazzino_command_state()

          txt_nome.activate()

        rescue Exception => e
          log_error(self, e)
        end

      end

      def chk_attivo_click(evt)
        update_ui()
      end

      def btn_variazione_click(evt)
        begin
          transfer_magazzino_from_view()
          magazzini_dlg = Views::Dialog::MagazziniDialog.new(self, false)
          magazzini_dlg.center_on_screen(Wx::BOTH)
          if magazzini_dlg.show_modal() == Wx::ID_OK
            self.magazzino = ctrl.load_magazzino(magazzini_dlg.selected)
            transfer_magazzino_to_view()
            update_ui()
            reset_magazzino_command_state()
            txt_nome.activate()

          else
            logger.debug("You pressed Cancel")
          end

          magazzini_dlg.destroy()

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
                if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
                  transfer_magazzino_from_view()
                  if self.magazzino.valid?
                    ctrl.save_magazzino()
                    evt_chg = Views::Base::CustomEvent::DettaglioMagazzinoChangedEvent.new(ctrl.search_magazzini())
                    # This sends the event for processing by listeners
                    process_event(evt_chg)
                    Wx::message_box('Salvataggio avvenuto correttamente.',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                    process_event(Views::Base::CustomEvent::BackEvent.new())
                  else
                    Wx::message_box(self.magazzino.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_magazzino_error_field()

                  end
                else
                  Wx::message_box('Utente non autorizzato.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
              else
                Wx::message_box("Licenza scaduta il #{ctrl.licenza.get_data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
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
            if ctrl.licenza.attiva?
              if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
                res = Wx::message_box("Confermi l'eliminazione del magazzino?",
                  'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  Wx::BusyCursor.busy() do
                    ctrl.delete_magazzino()
                    evt_chg = Views::Base::CustomEvent::DettaglioMagazzinoChangedEvent.new(ctrl.search_magazzini())
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
            else
              Wx::message_box("Licenza scaduta il #{ctrl.licenza.get_data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
            end
            txt_nome.activate()
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

      def reset_magazzino_command_state()
        if magazzino.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_nome, txt_descrizione]
        else
          if magazzino.modificabile?
            enable_widgets [btn_elimina, txt_nome, txt_descrizione]
          else
            disable_widgets [btn_elimina, txt_nome, txt_descrizione]
          end
        end
      end

      def update_ui()
        if chk_attivo.checked?
          enable_widgets [chk_predefinito]
        else
          chk_predefinito.view_data = false
          disable_widgets [chk_predefinito]
        end
      end

    end
  end
end
