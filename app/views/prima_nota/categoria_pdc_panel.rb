# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/categorie_pdc_dialog'

module Views
  module PrimaNota
    module CategoriaPdcPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui()

        model :categoria_pdc => {:attrs => [:codice,
            :descrizione,
            :type,
            :attivo]}
        
        controller :prima_nota

        logger.debug('initializing CategoriaPdcPanel...')
        xrc = Xrc.instance()
        
        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_descrizione', self, :extends => TextField)

        xrc.find('chce_type', self, :extends => ChoiceStringField) do |field|
          field.load_data([Models::CategoriaPdc::COSTO,
                           Models::CategoriaPdc::RICAVO,
                           Models::CategoriaPdc::ATTIVO,
                           Models::CategoriaPdc::PASSIVO],
              :label => :label,
              :include_blank => {:label => ''})
        end

        xrc.find('chk_attiva', self, :extends => CheckField)

        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuova', self)

        disable_widgets [btn_elimina]

        map_events(self)

        subscribe(:evt_azienda_changed) do
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

      def init_panel()
        reset_categoria_pdc_command_state()

        txt_codice.activate()
        
      end
      
      def reset_panel()
        begin
          reset_categoria_pdc()
          
          reset_categoria_pdc_command_state()

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
            if categoria_pdc = ctrl.load_categoria_pdc_by_codice(txt_codice.view_data)
              self.categoria_pdc = categoria_pdc
              transfer_categoria_pdc_to_view()
              reset_categoria_pdc_command_state()
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
          transfer_categoria_pdc_from_view()
          categorie_pdc_dlg = Views::Dialog::CategoriePdcDialog.new(self, false)
          categorie_pdc_dlg.center_on_screen(Wx::BOTH)
          if categorie_pdc_dlg.show_modal() == Wx::ID_OK
            self.categoria_pdc = ctrl.load_categoria_pdc(categorie_pdc_dlg.selected)
            transfer_categoria_pdc_to_view()
            reset_categoria_pdc_command_state()
            txt_codice.activate() if txt_codice.enabled?
            
          else
            logger.debug("You pressed Cancel")
          end

          categorie_pdc_dlg.destroy()

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
                if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
                  transfer_categoria_pdc_from_view()
                  if self.categoria_pdc.valid?
                    ctrl.save_categoria_pdc()
                    evt_chg = Views::Base::CustomEvent::CategoriaPdcChangedEvent.new(ctrl.search_categorie_pdc())
                    # This sends the event for processing by listeners
                    process_event(evt_chg)
                    Wx::message_box('Salvataggio avvenuto correttamente.',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                    process_event(Views::Base::CustomEvent::BackEvent.new())
                  else
                    Wx::message_box(self.categoria_pdc.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_categoria_pdc_error_field()

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
              if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
                res = Wx::message_box("Confermi l'eliminazione?",
                  'Domanda',
                  Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  Wx::BusyCursor.busy() do
                    ctrl.delete_categoria_pdc()
                    evt_chg = Views::Base::CustomEvent::CategoriaPdcChangedEvent.new(ctrl.search_categorie_pdc())
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
              Wx::message_box("Licenza scaduta il #{ctrl.licenza.data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
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
      
      def reset_categoria_pdc_command_state()
        if categoria_pdc.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione, chce_type]
        else
          if categoria_pdc.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione, chce_type]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione, chce_type]
          end
        end
      end

    end
  end
end