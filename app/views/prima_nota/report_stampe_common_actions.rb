# encoding: utf-8

require 'app/views/dialog/storico_residui_dialog'

module Views
  module PrimaNota
    module ReportStampeCommonActions
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :active_filter

      # viene chiamato al cambio folder
      def init_folder()
        txt_dal.activate()
      end

      def reset_folder()
        lstrep_scritture.reset()
        result_set_lstrep_scritture.clear()
        filtro.data_storico_residuo = nil
      end

      # Gestione eventi

      def chce_stampa_residuo_select(evt)
        begin
          enable_criteria(!evt.get_event_object().view_data)
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_pulisci_click(evt)
        begin
          reset_folder()
          self.active_filter = false
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_stampa_click(evt)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_stampe,
            :layout => 'Landscape',
            :margin_top => 40,
            :footer => false,
            :dati_azienda => dati_azienda
          )

        end

        if filtro.stampa_residuo
          Models::Scrittura.update_all("congelata = 1, data_residuo = '#{Date.today.to_s(:db)}'", "congelata = 0 and azienda_id = #{Models::Azienda.current.id}")
        end

      end

      def lstrep_scritture_item_activated(evt)
        if ident = evt.get_item().get_data()
          begin
            scrittura = ctrl.load_scrittura(ident[:id])
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
            elsif (not scrittura.esterna?)
              # lancio l'evento per la richiesta di dettaglio scrittura
              evt_dettaglio_scrittura = Views::Base::CustomEvent::DettaglioScritturaEvent.new(scrittura)
              # This sends the event for processing by listeners
              process_event(evt_dettaglio_scrittura)
            end
          rescue ActiveRecord::RecordNotFound
            Wx::message_box('Nessuna incasso/pagamento associato alla scrittura selezionata.',
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)

            return
          end

        end
      end

      private

      def enable_criteria(really=true)
        if really
          disable_widgets [btn_storico]
          enable_widgets [chce_anno, txt_dal, txt_al]
        else
          enable_widgets [btn_storico]
          disable_widgets [chce_anno, txt_dal, txt_al]
        end
      end
    end
  end
end
