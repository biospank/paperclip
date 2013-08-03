# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/prodotti_dialog'

module Views
  module Magazzino
    module ProdottoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui()

        model :prodotto => {:attrs => [:codice, 
                                       :bar_code,
                                       :descrizione,
                                       :prezzo_acquisto,
                                       :prezzo_vendita,
                                       :aliquota,
                                       :imponibile,
                                       :note,
                                       :attivo]}
        
        controller :magazzino

        logger.debug('initializing ProdottoPanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('lku_bar_code', self, :extends => LookupTextField) do |f|
          f.tool_tip = 'Usare il lettore oppure premere F5 per la ricerca manuale'
        end
        xrc.find('txt_descrizione', self, :extends => TextField)
        xrc.find('txt_prezzo_acquisto', self, :extends => DecimalField)
        xrc.find('txt_prezzo_vendita', self, :extends => DecimalField)
        xrc.find('lku_aliquota', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|aliquota| self.txt_descrizione_aliquota.view_data = (aliquota ? aliquota.descrizione : nil)},
                                :model => :aliquota,
                                :dialog => :aliquote_dialog,
                                :default => lambda {|aliquota| aliquota.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW,
                                :folder => Helpers::MagazzinoHelper::WXBRA_IMPOSTAZIONI_FOLDER)
        end

        subscribe(:evt_aliquota_changed) do |data|
          lku_aliquota.load_data(data)
        end

        subscribe(:evt_new_prodotto) do
          reset_panel()
        end

        xrc.find('txt_descrizione_aliquota', self, :extends => TextField)
        xrc.find('txt_imponibile', self, :extends => DecimalField)

        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('txt_note', self, :extends => TextField)

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
        #reset_prodotto_view()

        #reset_prodotto_command_state()

        lku_bar_code.activate()
        
      end
      
      def reset_panel()
        begin
          reset_prodotto_view()
          
          reset_prodotto_command_state()

          lku_bar_code.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def reset_prodotto_view()
        reset_prodotto()
        lku_aliquota.set_default()
      end
      
      def txt_codice_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if prodotto = ctrl.load_prodotto_by_codice(txt_codice.view_data)
              self.prodotto = prodotto
              transfer_prodotto_to_view()
              update_ui()
              reset_prodotto_command_state()
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

      # Gestione eventi
      # chiamato prima che il testo cambia
      def lku_bar_code_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            btn_variazione_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_bar_code_enter(evt)
        begin
          if prodotto = ctrl.load_prodotto_by_bar_code(lku_bar_code.view_data)
            self.prodotto = prodotto
          else
            self.prodotto = Models::Prodotto.new(:bar_code => lku_bar_code.view_data)
            lku_aliquota.set_default()
          end
          transfer_prodotto_to_view()
          update_ui()
          reset_prodotto_command_state()
          lku_bar_code.activate()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_aliquota_after_change()
        logger.debug("lku_aliquota_after_change")
        lku_aliquota.match_selection()
        transfer_prodotto_from_view
        self.prodotto.calcola_imponibile()
        transfer_prodotto_to_view
      end

      def txt_prezzo_vendita_loose_focus()
        transfer_prodotto_from_view
        self.prodotto.calcola_imponibile()
        transfer_prodotto_to_view
      end

      def chk_attivo_click(evt)
        update_ui()
      end
      
      def btn_variazione_click(evt)
        begin
          transfer_prodotto_from_view()
          prodotti_dlg = Views::Dialog::ProdottiDialog.new(self, false)
          prodotti_dlg.center_on_screen(Wx::BOTH)
          if prodotti_dlg.show_modal() == Wx::ID_OK
            self.prodotto = ctrl.load_prodotto(prodotti_dlg.selected)
            transfer_prodotto_to_view()
            update_ui()
            reset_prodotto_command_state()
            lku_bar_code.activate() if lku_bar_code.enabled?
            
          else
            logger.debug("You pressed Cancel")
          end

          prodotti_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
                transfer_prodotto_from_view()
                if self.prodotto.valid?
                  self.prodotto.calcola_imponibile()
                  ctrl.save_prodotto()
                  evt_chg = Views::Base::CustomEvent::ProdottoChangedEvent.new(ctrl.search_prodotti())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                  reset_panel()
                  process_event(Views::Base::CustomEvent::BackEvent.new())
                else
                  Wx::message_box(self.prodotto.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_prodotto_error_field()

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
            if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
              res = Wx::message_box("Confermi l'eliminazione del prodotto?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              if res == Wx::YES
                Wx::BusyCursor.busy() do
                  ctrl.delete_prodotto()
                  evt_chg = Views::Base::CustomEvent::ProdottoChangedEvent.new(ctrl.search_prodotti())
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
            lku_bar_code.activate()
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
      
      def reset_prodotto_command_state()
        if prodotto.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione]
        else
          if prodotto.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione]
          end
        end
      end

      def update_ui()

      end

    end
  end
end