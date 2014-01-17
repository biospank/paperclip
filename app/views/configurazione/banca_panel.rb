# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/banche_dialog'
require 'app/views/dialog/pdc_dialog'

module Views
  module Configurazione
    module BancaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog

      def ui()

        model :banca => {:attrs => [:codice, :descrizione, :conto_corrente, :iban,
                                    :agenzia, :telefono, :indirizzo, :pdc, :attiva, :predefinita]}
        
        controller :configurazione

        logger.debug('initializing BancaPanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_descrizione', self, :extends => TextField)
        xrc.find('txt_conto_corrente', self, :extends => TextField)
        xrc.find('txt_iban', self, :extends => TextField)
        xrc.find('txt_agenzia', self, :extends => TextField)
        xrc.find('txt_telefono', self, :extends => TextField)
        xrc.find('txt_indirizzo', self, :extends => TextField)

        xrc.find('lku_pdc', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_CONFIGURAZIONE_VIEW,
                                :folder => Helpers::ConfigurazioneHelper::WXBRA_AZIENDA_FOLDER)
        end

        xrc.find('txt_descrizione_pdc', self, :extends => TextField)
        xrc.find('chk_attiva', self, :extends => CheckField)
        xrc.find('chk_predefinita', self, :extends => CheckField)
        
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuova', self)

        disable_widgets [btn_elimina]
        
        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc.load_data(data)
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([lku_pdc]) : disable_widgets([lku_pdc])
        end

        subscribe(:evt_new_banca) do
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
          reset_banca()
          
          reset_banca_command_state()

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
            if banca = ctrl.load_banca_by_codice(txt_codice.view_data)
              self.banca = banca
              transfer_banca_to_view()
              update_ui()
              reset_banca_command_state()
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

      # sovrascritto per agganciare il filtro sul criterio di ricerca
      def lku_pdc_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.pdc_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_CONFIGURAZIONE_VIEW,
                  Helpers::ConfigurazioneHelper::WXBRA_AZIENDA_FOLDER
                ]
              )
              process_event(evt_new)
            end

            dlg.destroy()

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
          # se esiste ricerca solo le occorrenze associate ad un cliente
          transfer_banca_from_view()
          banche_dlg = Views::Dialog::BancheDialog.new(self, false)
          banche_dlg.center_on_screen(Wx::BOTH)
          if banche_dlg.show_modal() == Wx::ID_OK
            self.banca = ctrl.load_banca(banche_dlg.selected)
            transfer_banca_to_view()
            update_ui()
            reset_banca_command_state()
            txt_codice.activate()
            
          else
            logger.debug("You pressed Cancel")
          end

          banche_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
                transfer_banca_from_view()
                if pdc_compatibile?
                  if self.banca.valid?
                    ctrl.save_banca()
                    evt_chg = Views::Base::CustomEvent::BancaChangedEvent.new(ctrl.search_banche())
                    # This sends the event for processing by listeners
                    process_event(evt_chg)
                    Wx::message_box('Salvataggio avvenuto correttamente.',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                    process_event(Views::Base::CustomEvent::BackEvent.new())
                  else
                    Wx::message_box(self.banca.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_banca_error_field()

                  end
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
            if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
              res = Wx::message_box("Confermi l'eliminazione della banca?",
                'Domanda',
                Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)


              if res == Wx::YES
                Wx::BusyCursor.busy() do
                  ctrl.delete_banca()
                  evt_chg = Views::Base::CustomEvent::BancaChangedEvent.new(ctrl.search_banche())
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
      
      def reset_banca_command_state()
        if banca.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione,
                          txt_conto_corrente, txt_iban,
                          txt_agenzia, txt_telefono,
                          txt_indirizzo]
        else
          if banca.modificabile?
            enable_widgets [txt_codice, txt_descrizione,
                          txt_conto_corrente, txt_iban,
                          txt_agenzia, txt_telefono,
                          txt_indirizzo, btn_elimina]
          else
            disable_widgets [txt_codice, txt_descrizione,
                          txt_conto_corrente, txt_iban,
                          txt_agenzia, txt_telefono,
                          txt_indirizzo, btn_elimina]
          end
        end

        if configatron.bilancio.attivo
          if self.banca.new_record?
            lku_pdc.enable(true)
          else
            if lku_pdc.view_data
              if self.banca.modificabile?
                lku_pdc.enable(true)
              else
                lku_pdc.enable(false)
              end
            else
              lku_pdc.enable(true)
            end
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

      def pdc_compatibile?
        if configatron.bilancio.attivo
          if self.banca.pdc && self.banca.pdc.conto_economico?
            res = Wx::message_box("Il conto associato non è un conto patrimoniale.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                lku_pdc.activate()
                return false
              end

          end
        end

        return true
      end

      def pdc_sql_criteria()
        "pdc.type in ('#{Models::Pdc::ATTIVO}', '#{Models::Pdc::PASSIVO}')"
      end
    end
  end
end