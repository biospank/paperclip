# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/causali_dialog'

module Views
  module PrimaNota
    module CausaliPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui()

        model :causale => {:attrs => [:codice, 
                                       :descrizione,
                                       :banca,
                                       :attiva, 
                                       :predefinita, 
                                       :descrizione_agg,
                                       :cassa_dare,
                                       :cassa_avere,
                                       :banca_dare,
                                       :banca_avere,
                                       :fuori_partita_dare,
                                       :fuori_partita_avere,
                                       :pdc_dare,
                                       :pdc_avere]}
        
        controller :prima_nota

        logger.debug('initializing CausaliPanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_descrizione', self, :extends => TextField)
        xrc.find('lku_banca', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|banca| self.txt_descrizione_banca.view_data = (banca ? banca.descrizione : nil)},
                                :model => :banca,
                                :dialog => :banche_dialog,
                                :default => lambda {|banca| banca.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)

        xrc.find('lku_pdc_dare', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_dare', self, :extends => TextField)

        xrc.find('lku_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc_dare.load_data(data)
          lku_pdc_avere.load_data(data)
        end

        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        subscribe(:evt_new_causale) do
          reset_panel()
        end

        xrc.find('chk_attiva', self, :extends => CheckField)
        xrc.find('chk_predefinita', self, :extends => CheckField)
        xrc.find('txt_descrizione_agg', self, :extends => TextField)
        
        xrc.find('chk_cassa_dare', self, :extends => CheckField)
        xrc.find('chk_cassa_avere', self, :extends => CheckField)
        xrc.find('chk_banca_dare', self, :extends => CheckField)
        xrc.find('chk_banca_avere', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_dare', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_avere', self, :extends => CheckField)

        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuova', self)

        disable_widgets [btn_elimina]
        
        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([lku_pdc_dare, lku_pdc_avere]) : disable_widgets([lku_pdc_dare, lku_pdc_avere])
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
      
      def reset_causale_command_state()
        if causale.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione, 
                          lku_banca, txt_descrizione_agg,
                          chk_cassa_dare, chk_cassa_avere,
                          chk_banca_dare, chk_banca_avere,
                          chk_fuori_partita_dare, chk_fuori_partita_avere]
        else
          if causale.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione, 
                            lku_banca, txt_descrizione_agg,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione, 
                            txt_descrizione_agg,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere]

            if lku_banca.view_data
              lku_banca.enable(false)
            else
              if causale.movimento_di_banca?
                lku_banca.enable(true)
              else
                lku_banca.enable(false)
              end
            end

          end
        end

        if configatron.bilancio.attivo
          if self.causale.new_record?
            lku_pdc_dare.enable(true)
            lku_pdc_avere.enable(true)
          else
            if lku_pdc_dare.view_data
              if self.causale.modificabile?
                lku_pdc_dare.enable(true)
              else
                lku_pdc_dare.enable(false)
              end
            else
              lku_pdc_dare.enable(true)
            end
            if lku_pdc_avere.view_data
              if self.causale.modificabile?
                lku_pdc_avere.enable(true)
              else
                lku_pdc_avere.enable(false)
              end
            else
              lku_pdc_avere.enable(true)
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

    end
  end
end