# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/fornitori_dialog'
require 'app/views/dialog/righe_fattura_pdc_fornitori_dialog'
require 'app/views/dialog/fatture_fornitori_dialog'
require 'app/views/dialog/tipi_pagamento_dialog'
require 'app/views/dialog/banche_dialog'
require 'app/views/scadenzario/pagamenti_fattura_fornitore_panel'

module Views
  module Scadenzario
    module FatturaFornitorePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :dialog_sql_criteria, # utilizzato nelle dialog
                    :righe_fattura_pdc
                    
      def ui(container=nil)
        
        model :fornitore => {:attrs => [:denominazione, :p_iva]},
          :fattura_fornitore => {:attrs => [:num, 
                                            :data_emissione, 
                                            :importo,
                                            :nota_di_credito]}
        
        controller :scadenzario

        logger.debug('initializing FatturaFornitorePanel...')
        xrc = Xrc.instance()
        # Fattura fornitore
        
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_num', self, :extends => TextField) do |field|
          field.evt_char { |evt| txt_num_keypress(evt) }
        end
        xrc.find('txt_data_emissione', self, :extends => DateField) do |field|
          field.move_after_in_tab_order(txt_num)
        end
        xrc.find('txt_importo', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_importo_keypress(evt) }
        end
        xrc.find('btn_pdc', self)
        xrc.find('chk_nota_di_credito', self, :extends => CheckField)

        xrc.find('btn_fornitore', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_indietro', self)

        map_events(self)

        map_text_enter(self, {'txt_importo' => 'on_importo_enter'})

        xrc.find('PAGAMENTI_FATTURA_FORNITORE_PANEL', container, 
          :extends => Views::Scadenzario::PagamentiFatturaFornitorePanel, 
          :force_parent => self)

        pagamenti_fattura_fornitore_panel.ui()

        subscribe(:evt_dettaglio_pagamento) do |pagamento|
          self.fattura_fornitore = pagamento.fattura_fornitore
          self.fornitore = self.fattura_fornitore.fornitore
          transfer_fornitore_to_view()
          transfer_fattura_fornitore_to_view()
          pagamenti_fattura_fornitore_panel.display_pagamenti_fattura_fornitore(self.fattura_fornitore, pagamento)
          pagamenti_fattura_fornitore_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_fornitore_command_state()
          pagamenti_fattura_fornitore_panel.txt_importo.activate()

        end

        subscribe(:evt_dettaglio_fattura_fornitore_scadenzario) do |fattura|
          reset_panel()
          self.fattura_fornitore = fattura
          self.fornitore = self.fattura_fornitore.fornitore
          transfer_fornitore_to_view()
          transfer_fattura_fornitore_to_view()
          pagamenti_fattura_fornitore_panel.display_pagamenti_fattura_fornitore(self.fattura_fornitore)
          pagamenti_fattura_fornitore_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_fornitore_command_state()
          pagamenti_fattura_fornitore_panel.txt_importo.activate()

        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([btn_pdc]) : disable_widgets([btn_pdc])
        end

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      def init_panel()
        # imposto la data di oggi
        txt_data_emissione.view_data = Date.today if txt_data_emissione.view_data.blank?

        reset_fattura_fornitore_command_state()

        pagamenti_fattura_fornitore_panel.init_panel()
        
        txt_num.enabled? ? txt_num.activate() : pagamenti_fattura_fornitore_panel.txt_importo.activate()
      end
      
      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_fornitore()
          reset_fattura_fornitore()
          
          self.righe_fattura_pdc = nil

          # imposto la data di oggi
          txt_data_emissione.view_data = Date.today

          enable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_fornitore_command_state()

          pagamenti_fattura_fornitore_panel.reset_panel()

          txt_num.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def txt_num_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            btn_fornitore_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_importo_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              txt_data_emissione.activate()
            else
              pagamenti_fattura_fornitore_panel.txt_importo.activate()
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_importo_loose_focus()
        transfer_fattura_fornitore_from_view()
        pagamenti_fattura_fornitore_panel.riepilogo_fattura()
      end
      
      def on_importo_enter(evt)
        begin
          if configatron.bilancio.attivo
            transfer_fattura_fornitore_from_view()
            pagamenti_fattura_fornitore_panel.riepilogo_fattura()
            btn_pdc_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_pdc_click(evt)
        begin
          Wx::BusyCursor.busy() do
            if fornitore? && importo?
              self.righe_fattura_pdc ||= ctrl.search_righe_fattura_pdc_fornitori(self.fattura_fornitore) unless self.fattura_fornitore.new_record?
              rf_pdc_dlg = Views::Dialog::RigheFatturaPdcFornitoriDialog.new(self, (self.righe_fattura_pdc || []).dup)
              rf_pdc_dlg.center_on_screen(Wx::BOTH)
              answer = rf_pdc_dlg.show_modal()
              if answer == Wx::ID_OK
                self.righe_fattura_pdc = rf_pdc_dlg.result_set_lstrep_righe_fattura_pdc
                pagamenti_fattura_fornitore_panel.txt_importo.activate()
              elsif answer == rf_pdc_dlg.lku_aliquota.get_id
                evt_new = Views::Base::CustomEvent::NewEvent.new(:aliquota,
                  [
                    Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                    Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
                  ]
                )
                # This sends the event for processing by listeners
                process_event(evt_new)
              elsif answer == rf_pdc_dlg.lku_norma.get_id
                evt_new = Views::Base::CustomEvent::NewEvent.new(:norma,
                  [
                    Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                    Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
                  ]
                )
                # This sends the event for processing by listeners
                process_event(evt_new)
              elsif answer == rf_pdc_dlg.lku_pdc.get_id
                evt_new = Views::Base::CustomEvent::NewEvent.new(:pdc,
                  [
                    Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                    Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
                  ]
                )
                # This sends the event for processing by listeners
                process_event(evt_new)
              end

              rf_pdc_dlg.destroy()
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_fornitore_click(evt)
        begin
          Wx::BusyCursor.busy() do
            fornitori_dlg = Views::Dialog::FornitoriDialog.new(self)
            fornitori_dlg.center_on_screen(Wx::BOTH)
            answer = fornitori_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_panel()
              self.fornitore = ctrl.load_fornitore(fornitori_dlg.selected)
              self.fattura_fornitore.fornitore = self.fornitore
              transfer_fornitore_to_view()
              txt_num.activate()
            elsif answer == fornitori_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:fornitore, [Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW, Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER])
              # This sends the event for processing by listeners
              process_event(evt_new)
            else
              logger.debug("You pressed Cancel")
            end

            fornitori_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end
        
        evt.skip()
      end

      def btn_variazione_click(evt)
        begin
          Wx::BusyCursor.busy() do
            # se esiste ricerca solo le occorrenze associate ad un fornitore
            transfer_fornitore_from_view()
            self.dialog_sql_criteria = self.scadenzario_sql_criteria()
            fatture_fornitori_dlg = Views::Dialog::FattureFornitoriDialog.new(self)
            fatture_fornitori_dlg.center_on_screen(Wx::BOTH)
            if fatture_fornitori_dlg.show_modal() == Wx::ID_OK
              reset_panel()
              self.fattura_fornitore = ctrl.load_fattura_fornitore(fatture_fornitori_dlg.selected)
              self.fornitore = self.fattura_fornitore.fornitore
              transfer_fornitore_to_view()
              transfer_fattura_fornitore_to_view()
              pagamenti_fattura_fornitore_panel.display_pagamenti_fattura_fornitore(self.fattura_fornitore)
              pagamenti_fattura_fornitore_panel.riepilogo_fattura()

              disable_widgets [
                txt_num,
                txt_data_emissione,
                txt_importo,
                chk_nota_di_credito
              ]

              reset_fattura_fornitore_command_state()
              pagamenti_fattura_fornitore_panel.txt_importo.activate()

            else
              logger.debug("You pressed Cancel")
            end

            fatture_fornitori_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          # per controllare il tasto funzione F8 associato al salva
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::SCADENZARIO
                transfer_fattura_fornitore_from_view()
                if fornitore? && pdc_compilato? && pdc_compatibile?
                  if self.fattura_fornitore.valid?
                    ctrl.save_fattura_fornitore()

                    notify(:evt_scadenzario_fornitori_changed)

                    Wx::message_box('Salvataggio avvenuto correttamente',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                    # l'evento di controllo delle scadenze viene processato
                    # automaticamente dal programma ogni 5 min.
                    # lancio l'evento per il controllo delle scadenze
                    # utile nel caso venga salvato l'ultimo movimento in sospese
                    evt_scadenza = Views::Base::CustomEvent::ScadenzaInSospesoEvent.new()
                    # This sends the event for processing by listeners
                    process_event(evt_scadenza)
                  else
                    Wx::message_box(self.fattura_fornitore.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_fattura_fornitore_error_field()

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
          Wx::message_box("Il documento e' stato modificato da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
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
            if can? :write, Helpers::ApplicationHelper::Modulo::SCADENZARIO
              res = Wx::message_box("Confermi la cancellazione della fattura e tutti gli pagamenti collegati?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              Wx::BusyCursor.busy() do
                if res == Wx::YES
                  ctrl.delete_fattura_fornitore()
                  notify(:evt_scadenzario_fornitori_changed)
                  reset_panel()
                  # l'evento di controllo delle scadenze viene processato
                  # automaticamente dal programma ogni 5 min.
                  # lancio l'evento per il controllo delle scadenze
                  #evt_scadenza = Views::Base::CustomEvent::ScadenzaInSospesoEvent.new()
                  # This sends the event for processing by listeners
                  #process_event(evt_scadenza)
                end
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
      
      def btn_pulisci_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_indietro_click(evt)
        begin
          Wx::BusyCursor.busy() do
            reset_panel()
            # lancio l'evento per il controllo delle scadenze
            evt_scadenza = Views::Base::CustomEvent::ScadenzaInSospesoEvent.new()
            # This sends the event for processing by listeners
            process_event(evt_scadenza)
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def reset_fattura_fornitore_command_state()
        if fattura_fornitore.new_record?
          enable_widgets [btn_salva,btn_fornitore,btn_variazione]
          disable_widgets [btn_elimina]
        else
          if ctrl.movimenti_in_sospeso?
            disable_widgets [btn_fornitore,btn_variazione]
          else
            enable_widgets [btn_fornitore,btn_variazione]
          end
          enable_widgets [btn_salva,btn_elimina]
        end
        # gestione scadenze
        if ctrl.locked?
          btn_pulisci.hide()
          btn_indietro.show()
        else
          btn_pulisci.show()
          btn_indietro.hide()
        end
        layout()
      end

      def fornitore?
        if self.fornitore.new_record?
          Wx::message_box('Selezionare un fornitore',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          btn_fornitore.set_focus()
          return false
        else
          return true
        end

      end

      def importo?
        if self.fattura_fornitore.importo.blank? || self.fattura_fornitore.importo == 0
          Wx::message_box("Inserire l'importo",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          txt_importo.activate()
          return false
        else
          return true
        end

      end

      def pdc_compilato?
        if configatron.bilancio.attivo && self.righe_fattura_pdc.blank?
          Wx::message_box("Dettaglio Iva incompleto.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          btn_pdc.set_focus()
          return false
        else
          return true
        end

      end

      def pdc_compatibile?
        totale_righe = 0.0
        if configatron.bilancio.attivo

          self.righe_fattura_pdc.each do |riga|
            if riga.valid_record?
              totale_righe += (riga.imponibile + riga.iva)
            end
          end

          if Helpers::ApplicationHelper.real(totale_righe) != Helpers::ApplicationHelper.real(self.fattura_fornitore.importo)
              Wx::message_box("Il dettaglio iva non corrisponde al totale della fattura.",
                'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            btn_pdc.set_focus()
            return false
          end
        end

        return true

      end

      def scadenzario_sql_criteria
        # noop
      end
      
    end
  end
end