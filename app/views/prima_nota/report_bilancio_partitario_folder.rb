# encoding: utf-8

module Views
  module PrimaNota
    module ReportBilancioPartitarioFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :active_filter, :totale_dare, :totale_avere

      def ui
        model :filtro => {:attrs => []}
        controller :prima_nota

        logger.debug('initializing Bilancio ReportBilancioPartitarioFolder...')
        xrc = Xrc.instance()

        xrc.find('lku_pdc', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_REPORT_BILANCIO_FOLDER)
        end

        lku_pdc.load_data(Models::Pdc.search(:all,
            :joins => :categoria_pdc
          )
        )

        subscribe(:evt_cliente_changed) do |data|
          lku_pdc.load_data(Models::Pdc.search(:all,
              :joins => :categoria_pdc
            )
          )
        end

        subscribe(:evt_fornitore_changed) do |data|
          lku_pdc.load_data(Models::Pdc.search(:all,
              :joins => :categoria_pdc
            )
          )
        end

        xrc.find('txt_descrizione_pdc', self, :extends => TextField)

        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_scrittura_changed) do |data|
          chce_anno.load_data(data, :select => :last)
        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)

        xrc.find('lstrep_scritture', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Descrizione', :width => 350, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Conto', :width => 80, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Descrizione conto', :width => 300, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Dare', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Avere', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :data, :format => :date, :if => lambda {|data| !data.blank? }},
              {:attr => :descrizione},
              {:attr => :conto},
              {:attr => :descrizione_conto},
              {:attr => :dare, :format => :currency},
              {:attr => :avere, :format => :currency}])

        end

        xrc.find('cpt_totale', self)
        xrc.find('lbl_totale', self)

        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_dettaglio_report_partitario_bilancio) do |evt|
          reset_folder()
          lku_pdc.view_data = evt.pdc
          chce_anno.view_data = evt.filtro.anno
          txt_dal.view_data = evt.filtro.dal
          txt_al.view_data = evt.filtro.al
          transfer_filtro_from_view()
          self.result_set_lstrep_scritture = ctrl.report_partitario_bilancio()
          lstrep_scritture.display_matrix(result_set_lstrep_scritture)
          if(Helpers::ApplicationHelper.real(self.totale_dare) >= Helpers::ApplicationHelper.real(self.totale_avere))
            self.cpt_totale.label = "Totale Dare:"
            self.lbl_totale.label = Helpers::ApplicationHelper.currency(self.totale_dare - self.totale_avere)
          else
            self.cpt_totale.label = "Totale Avere"
            self.lbl_totale.label = Helpers::ApplicationHelper.currency(self.totale_avere - self.totale_dare)
          end
          transfer_filtro_to_view()
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F9, btn_stampa.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_pulisci.get_id ]
        ]
        self.accelerator_table = acc_table
      end
      
      # viene chiamato al cambio folder
      def init_folder()
        lku_pdc.activate()
      end

      def reset_folder()
        lstrep_scritture.reset()
        result_set_lstrep_scritture.clear()
        reset_totali()
      end

      # Gestione eventi

      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            reset_folder()
            transfer_filtro_from_view()
            unless filtro.pdc
                Wx::message_box('Selezionare un conto.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              lku_pdc.activate()
              return
            end
            self.result_set_lstrep_scritture = ctrl.report_partitario_bilancio()
            lstrep_scritture.display_matrix(result_set_lstrep_scritture)
            if(Helpers::ApplicationHelper.real(self.totale_dare) >= Helpers::ApplicationHelper.real(self.totale_avere))
              self.cpt_totale.label = "Totale Dare:"
              self.lbl_totale.label = Helpers::ApplicationHelper.currency(self.totale_dare - self.totale_avere)
            else
              self.cpt_totale.label = "Totale Avere"
              self.lbl_totale.label = Helpers::ApplicationHelper.currency(self.totale_avere - self.totale_dare)
            end
            transfer_filtro_to_view()
            self.active_filter = true
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def btn_pulisci_click(evt)
        logger.debug("Cliccato sul bottone pulisci!")
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

          generate(:report_partitario,
            :layout => 'Landscape',
            :margin_top => 40,
            :footer => false,
            :dati_azienda => dati_azienda
          )

          if filtro.stampa_residuo
            Models::Scrittura.update_all("congelata = 1, data_residuo = '#{Date.today.to_s(:db)}'", "congelata = 0 and azienda_id = #{Models::Azienda.current.id}")
          end

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::PrimaNotaHelper::PartitarioHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::PrimaNotaHelper::PartitarioBodyTemplatePath)
          ).result(binding)
        )

      end

#      def lstrep_scritture_item_activated(evt)
#        if ident = evt.get_item().get_data()
#          begin
#            scrittura = ctrl.load_scrittura(ident[:id])
#            if scrittura.esterna? # and not scrittura.stornata? le scritture stornate non vengono visualizzate
#              if pfc = scrittura.pagamento_fattura_cliente
#                if mpc = scrittura.maxi_pagamento_cliente
#                  incassi = mpc.pagamenti_fattura_cliente
#                  rif_incassi_dlg = Views::Dialog::RifMaxiIncassiDialog.new(self, incassi)
#                  rif_incassi_dlg.center_on_screen(Wx::BOTH)
#                  answer = rif_incassi_dlg.show_modal()
#                  if answer == Wx::ID_OK
#                    pfc = ctrl.load_incasso(rif_incassi_dlg.selected)
#                    rif_incassi_dlg.destroy()
#                    # lancio l'evento per la richiesta di dettaglio fattura
#                    evt_dettaglio_incasso = Views::Base::CustomEvent::DettaglioIncassoEvent.new(pfc)
#                    # This sends the event for processing by listeners
#                    process_event(evt_dettaglio_incasso)
#                  end
#                else
#                  # lancio l'evento per la richiesta di dettaglio fattura
#                  evt_dettaglio_incasso = Views::Base::CustomEvent::DettaglioIncassoEvent.new(pfc)
#                  # This sends the event for processing by listeners
#                  process_event(evt_dettaglio_incasso)
#                end
#              elsif pff = scrittura.pagamento_fattura_fornitore
#                if mpf = scrittura.maxi_pagamento_fornitore
#                  pagamenti = mpf.pagamenti_fattura_fornitore
#                  rif_pagamenti_dlg = Views::Dialog::RifMaxiPagamentiDialog.new(self, pagamenti)
#                  rif_pagamenti_dlg.center_on_screen(Wx::BOTH)
#                  answer = rif_pagamenti_dlg.show_modal()
#                  if answer == Wx::ID_OK
#                    pff = ctrl.load_pagamento(rif_pagamenti_dlg.selected)
#                    rif_pagamenti_dlg.destroy()
#                    # lancio l'evento per la richiesta di dettaglio fattura
#                    evt_dettaglio_pagamento = Views::Base::CustomEvent::DettaglioPagamentoEvent.new(pff)
#                    # This sends the event for processing by listeners
#                    process_event(evt_dettaglio_pagamento)
#                  end
#                else
#                  # lancio l'evento per la richiesta di dettaglio fattura
#                  evt_dettaglio_pagamento = Views::Base::CustomEvent::DettaglioPagamentoEvent.new(pff)
#                  # This sends the event for processing by listeners
#                  process_event(evt_dettaglio_pagamento)
#                end
#              end
#
#            else
#              # lancio l'evento per la richiesta di dettaglio scrittura
#              evt_dettaglio_scrittura = Views::Base::CustomEvent::DettaglioScritturaEvent.new(scrittura)
#              # This sends the event for processing by listeners
#              process_event(evt_dettaglio_scrittura)
#            end
#          rescue ActiveRecord::RecordNotFound
#            Wx::message_box('Nessuna incasso/pagamento associato alla scrittura selezionata.',
#              'Info',
#              Wx::OK | Wx::ICON_INFORMATION, self)
#
#            return
#          end
#
#        end
#      end

      def include_hidden_pdc()
        true
      end

      private

      def reset_totali()
        self.totale_dare = 0.0
        self.totale_avere = 0.0
        self.cpt_totale.label = 'Totale:'
        self.lbl_totale.label = ''
      end

    end
  end
end
