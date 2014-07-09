# encoding: utf-8

module Views
  module PrimaNota
    module ScrittureCommonActions
      include Views::Base::Folder
      include Helpers::MVCHelper

      WX_ID_F2 = Wx::ID_ANY

      # riferimento della scrittura selezionata in lista
      attr_accessor :scrittura_ref,
        :dialog_sql_criteria # utilizzato nelle dialog

      def init_folder()
        reset_gestione_riga()
        update_riga_ui()

        txt_data_operazione.activate()
      end

      # Resetta il pannello reinizializzando il modello
      def reset_folder()
        begin
          reset_gestione_riga()
          update_riga_ui()

          txt_data_operazione.activate()

        rescue Exception => e
          log_error(self, e)
        end

      end

      def on_ricerca_text_enter(evt)
        begin
          btn_ricerca_click(evt)
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_ricerca_click(evt)
        begin
          Wx::BusyCursor.busy() do
            transfer_filtro_from_view()
            display_scritture()
            riepilogo_saldi()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
                  if scrittura.esterna?
                    Wx::message_box("Questa scrittura non puo' essere eliminata.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                  else
                    if scrittura.congelata?
                      if scrittura.stornata?
                        Wx::message_box("Questa scrittura è già stata stornata.",
                          'Info',
                          Wx::OK | Wx::ICON_INFORMATION, self)
                      else
                        res = Wx::message_box("Si sta eliminando una scrittura definitiva:\nLa conferma effettuerà uno storno della stessa. Confermi?",
                          'Domanda',
                            Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)
                        if res == Wx::YES
                          ctrl.storno_scrittura(scrittura)
                          if filtro.dal || filtro.al
                            notify(:evt_prima_nota_changed, ctrl.ricerca_scritture())
                          else
                            notify(:evt_prima_nota_changed, ctrl.search_scritture())
                          end
                        end
                      end
                    else
                      res = Wx::message_box("Confermi la cancellazione?",
                        'Domanda',
                          Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res == Wx::YES
                        ctrl.delete_scrittura()
                        if filtro.dal || filtro.al
                          notify(:evt_prima_nota_changed, ctrl.ricerca_scritture())
                        else
                          notify(:evt_prima_nota_changed, ctrl.search_scritture())
                        end
                      end
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
            end
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)

        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_nuova_click(evt)
        begin
          reset_filtro()
          notify(:evt_prima_nota_changed, ctrl.search_scritture())
        rescue Exception => e
          log_error(self, e)
        end

      end

      def display_scritture(scritture=nil)
        if scritture
          self.result_set_lstrep_scritture = scritture
        else
          self.result_set_lstrep_scritture = ctrl.ricerca_scritture()
        end
        lstrep_scritture.display(self.result_set_lstrep_scritture)
      end

      def lstrep_scritture_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_scritture.each do |record|
            if record.ident() == row_id
              # faccio una copia per evitare
              # la modifica di quello in lista
              self.scrittura = record.dup
              break
            end
          end
          transfer_scrittura_to_view()
          update_riga_ui()
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_scritture_item_activated(evt)
        begin
          if scrittura.esterna? and not scrittura.stornata?
            if pfc = scrittura.pagamento_fattura_cliente
              if mpc = scrittura.maxi_pagamento_cliente
                incassi = mpc.pagamenti_fattura_cliente
                rif_incassi_dlg = Views::Dialog::RifMaxiIncassiDialog.new(self, incassi)
                rif_incassi_dlg.center_on_screen(Wx::BOTH)
                answer = rif_incassi_dlg.show_modal()
                if answer == Wx::ID_OK
                  pfc = ctrl.load_incasso(rif_incassi_dlg.selected)
                  rif_incassi_dlg.destroy()
                  # lancio l'evento per la richiesta di dettaglio fattura
                  evt_dettaglio_incasso = Views::Base::CustomEvent::DettaglioIncassoEvent.new(pfc)
                  # This sends the event for processing by listeners
                  process_event(evt_dettaglio_incasso)
                end
              else
                # lancio l'evento per la richiesta di dettaglio fattura
                evt_dettaglio_incasso = Views::Base::CustomEvent::DettaglioIncassoEvent.new(pfc)
                # This sends the event for processing by listeners
                process_event(evt_dettaglio_incasso)
              end
            elsif pff = scrittura.pagamento_fattura_fornitore
              if mpf = scrittura.maxi_pagamento_fornitore
                pagamenti = mpf.pagamenti_fattura_fornitore
                rif_pagamenti_dlg = Views::Dialog::RifMaxiPagamentiDialog.new(self, pagamenti)
                rif_pagamenti_dlg.center_on_screen(Wx::BOTH)
                answer = rif_pagamenti_dlg.show_modal()
                if answer == Wx::ID_OK
                  pff = ctrl.load_pagamento(rif_pagamenti_dlg.selected)
                  rif_pagamenti_dlg.destroy()
                  # lancio l'evento per la richiesta di dettaglio fattura
                  evt_dettaglio_pagamento = Views::Base::CustomEvent::DettaglioPagamentoEvent.new(pff)
                  # This sends the event for processing by listeners
                  process_event(evt_dettaglio_pagamento)
                end
              else
                # lancio l'evento per la richiesta di dettaglio fattura
                evt_dettaglio_pagamento = Views::Base::CustomEvent::DettaglioPagamentoEvent.new(pff)
                # This sends the event for processing by listeners
                process_event(evt_dettaglio_pagamento)
              end
            end
          elsif !scrittura.esterna? and !scrittura.congelata?
            txt_data_operazione.activate if txt_data_operazione.enabled?
          end
        rescue ActiveRecord::RecordNotFound
          Wx::message_box('Nessuna incasso/pagamento associato alla scrittura selezionata.',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          return
        end

      end

      def activate_field(*args)
        args.each do |txt|
          if txt.enabled?
            if txt.respond_to? 'activate'
              txt.activate()
            else
              txt.set_focus()
            end
            break
          end
        end
      end

    end
  end
end
