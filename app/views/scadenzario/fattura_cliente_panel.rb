# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'
require 'app/views/dialog/fatture_clienti_dialog'
require 'app/views/dialog/tipi_pagamento_dialog'
require 'app/views/dialog/banche_dialog'
require 'app/views/scadenzario/incassi_fattura_cliente_panel'

module Views
  module Scadenzario
    module FatturaClientePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog
      
      def ui(container=nil)
        
        model :cliente => {:attrs => [:denominazione, :p_iva]},
          :fattura_cliente_scadenzario => {:attrs => [:num, 
                                            :data_emissione, 
                                            :importo,
                                            :nota_di_credito],
                                          :alias => :fattura_cliente}
        
        controller :scadenzario

        logger.debug('initializing FatturaClientePanel...')
        xrc = Xrc.instance()
        # Fattura cliente
        
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
        xrc.find('chk_nota_di_credito', self, :extends => CheckField)

        xrc.find('btn_cliente', self)
        xrc.find('btn_fattura', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_indietro', self)

        map_events(self)

        xrc.find('INCASSI_FATTURA_CLIENTE_PANEL', container, 
          :extends => Views::Scadenzario::IncassiFatturaClientePanel, 
          :force_parent => self)

        incassi_fattura_cliente_panel.ui()

        subscribe(:evt_dettaglio_incasso) do |incasso|
          self.fattura_cliente = incasso.fattura_cliente_scadenzario # importante deve essere di tipo fattura_cliente_scadenzario
          self.cliente = self.fattura_cliente.cliente
          transfer_cliente_to_view()
          transfer_fattura_cliente_to_view()
          incassi_fattura_cliente_panel.display_incassi_fattura_cliente(self.fattura_cliente, incasso)
          incassi_fattura_cliente_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_cliente_command_state()
          incassi_fattura_cliente_panel.txt_importo.activate()

        end
        
        subscribe(:evt_dettaglio_fattura_cliente_scadenzario) do |fattura|
          reset_panel()
          self.fattura_cliente = fattura # importante deve essere di tipo fattura_cliente_scadenzario
          self.cliente = self.fattura_cliente.cliente
          transfer_cliente_to_view()
          transfer_fattura_cliente_to_view()
          incassi_fattura_cliente_panel.display_incassi_fattura_cliente(self.fattura_cliente)
          incassi_fattura_cliente_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_cliente_command_state()
          incassi_fattura_cliente_panel.txt_importo.activate()

        end
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      def init_panel()
        # imposto la data di oggi
        txt_data_emissione.view_data = Date.today if txt_data_emissione.view_data.blank?

        reset_fattura_cliente_command_state()

        incassi_fattura_cliente_panel.init_panel()
        
        txt_num.enabled? ? txt_num.activate() : incassi_fattura_cliente_panel.txt_importo.activate()
      end
      
      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_cliente()
          reset_fattura_cliente()
          
          # imposto la data di oggi
          txt_data_emissione.view_data = Date.today

          enable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_cliente_command_state()

          incassi_fattura_cliente_panel.reset_panel()

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
            btn_cliente_click(evt)
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
              incassi_fattura_cliente_panel.txt_importo.activate()
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_importo_loose_focus()
        transfer_fattura_cliente_from_view()
        incassi_fattura_cliente_panel.riepilogo_fattura()
      end
      
      def btn_cliente_click(evt)
        begin
          Wx::BusyCursor.busy() do
            clienti_dlg = Views::Dialog::ClientiDialog.new(self)
            clienti_dlg.center_on_screen(Wx::BOTH)
            answer = clienti_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_panel()
              self.cliente = ctrl.load_cliente(clienti_dlg.selected)
              self.fattura_cliente.cliente = self.cliente
              transfer_cliente_to_view()
              txt_num.activate()
            elsif answer == clienti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:cliente, [Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW, Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER])
              # This sends the event for processing by listeners
              process_event(evt_new)
            else
              logger.debug("You pressed Cancel")
            end

            clienti_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end
        
        evt.skip()
      end

      def btn_fattura_click(evt)
        begin
          Wx::BusyCursor.busy() do
            # se esiste ricerca solo le occorrenze associate ad un cliente
            transfer_cliente_from_view()
            self.dialog_sql_criteria = self.fattura_sql_criteria()
            fatture_clienti_dlg = Views::Dialog::FattureClientiDialog.new(self)
            fatture_clienti_dlg.center_on_screen(Wx::BOTH)
            if fatture_clienti_dlg.show_modal() == Wx::ID_OK
              self.fattura_cliente = ctrl.load_fattura_cliente(fatture_clienti_dlg.selected)
              self.cliente = self.fattura_cliente.cliente
              transfer_cliente_to_view()
              transfer_fattura_cliente_to_view()
              incassi_fattura_cliente_panel.display_incassi_fattura_cliente(self.fattura_cliente)
              incassi_fattura_cliente_panel.riepilogo_fattura()

              if fattura_cliente.ha_registrazioni_in_prima_nota? ||
                  fattura_cliente.da_fatturazione?
                disable_widgets [
                  txt_num,
                  txt_data_emissione,
                  txt_importo,
                  chk_nota_di_credito
                ]
              else
                enable_widgets [
                  txt_num,
                  txt_data_emissione,
                  txt_importo,
                  chk_nota_di_credito
                ]
              end

              reset_fattura_cliente_command_state()
              incassi_fattura_cliente_panel.txt_importo.activate()

            else
              logger.debug("You pressed Cancel")
            end

            fatture_clienti_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_variazione_click(evt)
        begin
          Wx::BusyCursor.busy() do
            # se esiste ricerca solo le occorrenze associate ad un cliente
            transfer_cliente_from_view()
            self.dialog_sql_criteria = self.scadenzario_sql_criteria()
            fatture_clienti_dlg = Views::Dialog::FattureClientiDialog.new(self)
            fatture_clienti_dlg.center_on_screen(Wx::BOTH)
            if fatture_clienti_dlg.show_modal() == Wx::ID_OK
              self.fattura_cliente = ctrl.load_fattura_cliente(fatture_clienti_dlg.selected)
              self.cliente = self.fattura_cliente.cliente
              transfer_cliente_to_view()
              transfer_fattura_cliente_to_view()
              incassi_fattura_cliente_panel.display_incassi_fattura_cliente(self.fattura_cliente)
              incassi_fattura_cliente_panel.riepilogo_fattura()

              disable_widgets [
                txt_num,
                txt_data_emissione,
                txt_importo,
                chk_nota_di_credito
              ]

  #            if fattura_cliente.ha_registrazioni_in_prima_nota?
  #              Wx::message_box("Fattura non modificabile.",
  #                'Avvertenza',
  #                Wx::OK | Wx::ICON_WARNING, self)
  #            end

              reset_fattura_cliente_command_state()
              incassi_fattura_cliente_panel.txt_importo.activate()

            else
              logger.debug("You pressed Cancel")
            end

            fatture_clienti_dlg.destroy()
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
                transfer_fattura_cliente_from_view()
                if cliente?
                  if self.fattura_cliente.valid?
                    ctrl.save_fattura_cliente()

                    notify(:evt_scadenzario_clienti_changed)

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
                    Wx::message_box(self.fattura_cliente.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_fattura_cliente_error_field()

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
              res = Wx::message_box("Confermi la cancellazione della fattura e tutti gli incassi collegati?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              Wx::BusyCursor.busy() do
                if res == Wx::YES
                  ctrl.delete_fattura_cliente()
                  notify(:evt_scadenzario_clienti_changed)
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
      
      def reset_fattura_cliente_command_state()
        if fattura_cliente.new_record?
          enable_widgets [btn_salva,btn_cliente,btn_variazione,btn_fattura]
          disable_widgets [btn_elimina]
        else
          if ctrl.movimenti_in_sospeso?
            disable_widgets [btn_cliente,btn_variazione,btn_fattura]
          else
            enable_widgets [btn_cliente,btn_variazione,btn_fattura]
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

      def fattura_sql_criteria
        "da_scadenzario = 0 and da_fatturazione = 1"
      end
      
      def scadenzario_sql_criteria
        "da_scadenzario = 1 and (da_fatturazione = 0 or da_fatturazione = 1)"
      end
      
    end
  end
end