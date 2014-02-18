# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/tipi_pagamento_dialog'

module Views
  module Scadenzario
    module IncassoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog dei conti
      
      def ui()

        model :tipo_pagamento_cliente => {:attrs => [:codice, 
                                       :descrizione,
                                       :banca,
                                       :attivo, 
                                       :predefinito, 
                                       :cassa_dare,
                                       :cassa_avere,
                                       :banca_dare,
                                       :banca_avere,
                                       :fuori_partita_dare,
                                       :fuori_partita_avere,
                                       :nc_cassa_dare,
                                       :nc_cassa_avere,
                                       :nc_banca_dare,
                                       :nc_banca_avere,
                                       :nc_fuori_partita_dare,
                                       :nc_fuori_partita_avere,
                                        :pdc_dare,
                                        :pdc_avere],
                                     :alias => :incasso}
        
        controller :scadenzario

        logger.debug('initializing IncassoPanel...')
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
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        subscribe(:evt_new_tipo_incasso) do
          reset_panel()
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)

        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('chk_predefinito', self, :extends => CheckField)
        
        xrc.find('chk_cassa_dare', self, :extends => CheckField)
        xrc.find('chk_cassa_avere', self, :extends => CheckField)
        xrc.find('chk_banca_dare', self, :extends => CheckField)
        xrc.find('chk_banca_avere', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_dare', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_avere', self, :extends => CheckField)

        xrc.find('chk_nc_cassa_dare', self, :extends => CheckField)
        xrc.find('chk_nc_cassa_avere', self, :extends => CheckField)
        xrc.find('chk_nc_banca_dare', self, :extends => CheckField)
        xrc.find('chk_nc_banca_avere', self, :extends => CheckField)
        xrc.find('chk_nc_fuori_partita_dare', self, :extends => CheckField)
        xrc.find('chk_nc_fuori_partita_avere', self, :extends => CheckField)

        xrc.find('lku_pdc_dare', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_dare', self, :extends => TextField)

        xrc.find('lku_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc_dare.load_data(data)
          lku_pdc_avere.load_data(data)
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([lku_pdc_dare, lku_pdc_avere]) : disable_widgets([lku_pdc_dare, lku_pdc_avere])
        end

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

        reset_incasso_command_state()

        txt_codice.activate()
        
      end
      
      def reset_panel()
        begin
          reset_incasso()
          
          reset_incasso_command_state()

          txt_codice.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def txt_codice_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if incasso = ctrl.load_tipo_pagamento_cliente_by_codice(txt_codice.view_data)
              self.incasso = incasso
              transfer_incasso_to_view()
              update_ui()
              reset_incasso_command_state()
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

      def chk_attivo_click(evt)
        update_ui()
      end
      
      def lku_pdc_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.dare_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc_dare.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_dare_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER
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

      def lku_pdc_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.avere_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc_avere.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_avere_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER
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

      def btn_variazione_click(evt)
        begin
          transfer_incasso_from_view()
          tipi_pagamento_dlg = Views::Dialog::TipiPagamentoDialog.new(self, false)
          tipi_pagamento_dlg.center_on_screen(Wx::BOTH)
          if tipi_pagamento_dlg.show_modal() == Wx::ID_OK
            self.incasso = ctrl.load_tipo_pagamento_cliente(tipi_pagamento_dlg.selected)
            transfer_incasso_to_view()
            update_ui()
            reset_incasso_command_state()
            txt_codice.activate() if txt_codice.enabled?
            
          else
            logger.debug("You pressed Cancel")
          end

          tipi_pagamento_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::SCADENZARIO
                transfer_incasso_from_view()
                if self.incasso.valid?
                  if incasso_compatibile?
                    ctrl.save_incasso()
                    evt_chg = Views::Base::CustomEvent::TipoPagamentoClienteChangedEvent.new(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::CLIENTI))
                    # This sends the event for processing by listeners
                    process_event(evt_chg)
                    Wx::message_box('Salvataggio avvenuto correttamente.',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                    process_event(Views::Base::CustomEvent::BackEvent.new())
                  end
                else
                  Wx::message_box(self.incasso.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_incasso_error_field()

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
            if can? :write, Helpers::ApplicationHelper::Modulo::SCADENZARIO
              res = Wx::message_box("Confermi l'eliminazione dell' incasso?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              if res == Wx::YES
                Wx::BusyCursor.busy() do
                  ctrl.delete_incasso()
                  evt_chg = Views::Base::CustomEvent::TipoPagamentoClienteChangedEvent.new(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::CLIENTI))
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
      
      def btn_nuovo_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def reset_incasso_command_state()
        if incasso.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione, lku_banca,
                          chk_cassa_dare, chk_cassa_avere,
                          chk_banca_dare, chk_banca_avere,
                          chk_fuori_partita_dare, chk_fuori_partita_avere,
                          chk_nc_cassa_dare, chk_nc_cassa_avere,
                          chk_nc_banca_dare, chk_nc_banca_avere,
                          chk_nc_fuori_partita_dare, chk_nc_fuori_partita_avere]
        else
          if incasso.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione, lku_banca,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere,
                            chk_nc_cassa_dare, chk_nc_cassa_avere,
                            chk_nc_banca_dare, chk_nc_banca_avere,
                            chk_nc_fuori_partita_dare, chk_nc_fuori_partita_avere]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione, lku_banca,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere,
                            chk_nc_cassa_dare, chk_nc_cassa_avere,
                            chk_nc_banca_dare, chk_nc_banca_avere,
                            chk_nc_fuori_partita_dare, chk_nc_fuori_partita_avere]
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

      def categoria()
        Helpers::AnagraficaHelper::CLIENTI
      end

      def dare_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::COSTO}')"
      end

      def avere_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::RICAVO}')"
      end

      def incasso_compatibile?

        if configatron.bilancio.attivo
          if self.incasso.pdc_dare && self.incasso.pdc_dare.ricavo?
            res = Wx::message_box("Il conto in dare non è un costo.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                lku_pdc_dare.activate()
                return false
              end
          end

          if self.incasso.pdc_avere && self.incasso.pdc_avere.costo?
            res = Wx::message_box("Il conto in avere non è un ricavo.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                lku_pdc_avere.activate()
                return false
              end
          end

          if(((self.incasso.pdc_dare && self.incasso.pdc_dare.costo?) &&
                (self.incasso.pdc_avere && self.incasso.pdc_avere.ricavo?)) ||
              ((self.incasso.pdc_dare && self.incasso.pdc_dare.ricavo?) &&
                (self.incasso.pdc_avere && self.incasso.pdc_avere.costo?)))

            res = Wx::message_box("Presenza di due conti economici.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                lku_pdc_dare.activate()
                return false
              end
          end

          # se uno dei conti dell'incasso ha una banca associata
          if((self.incasso.pdc_dare && self.incasso.pdc_dare.banca) || (self.incasso.pdc_avere && self.incasso.pdc_avere.banca))
            # ma non e' un incasso che movimenta la banca
            if((!self.incasso.movimento_di_banca?) && (!self.incasso.movimento_di_banca?(true)))
              Wx::message_box("Il conto selezionato prevede un movimento di banca.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              txt_banca_dare.activate

              return false
            end
          # se i conti dell'incasso non hanno una banca associata
          else
            # ma e' un incasso che movimenta la banca
            if((self.incasso.movimento_di_banca?) || (self.incasso.movimento_di_banca?(true)))
              Wx::message_box("Importo banca non compatibile:\nuno dei conti selezionati deve avere una banca associata.\nPremere F5 per selezionare un conto con la banca oppure associare la banca a un conto\nnel pannello 'prima nota -> piano dei conti -> gestione conti'.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              lku_pdc_dare.activate

              return false
            end
          end
        end

        return true
      end

    end
  end
end