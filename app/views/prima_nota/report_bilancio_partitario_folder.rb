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

        xrc.find('lbl_totale_dare', self)
        xrc.find('lbl_totale_avere', self)
        xrc.find('cpt_saldo', self)
        xrc.find('lbl_saldo', self)

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
          lbl_totale_dare.label = Helpers::ApplicationHelper.currency(self.totale_dare)
          lbl_totale_avere.label = Helpers::ApplicationHelper.currency(self.totale_avere)
          if(Helpers::ApplicationHelper.real(self.totale_dare) >= Helpers::ApplicationHelper.real(self.totale_avere))
            self.cpt_saldo.label = "Saldo dare:"
            self.lbl_saldo.label = Helpers::ApplicationHelper.currency(self.totale_dare - self.totale_avere)
          else
            self.cpt_saldo.label = "Saldo avere:"
            self.lbl_saldo.label = Helpers::ApplicationHelper.currency(self.totale_avere - self.totale_dare)
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
            lbl_totale_dare.label = Helpers::ApplicationHelper.currency(self.totale_dare)
            lbl_totale_avere.label = Helpers::ApplicationHelper.currency(self.totale_avere)
            if(Helpers::ApplicationHelper.real(self.totale_dare) >= Helpers::ApplicationHelper.real(self.totale_avere))
              self.cpt_saldo.label = "Saldo dare:"
              self.lbl_saldo.label = Helpers::ApplicationHelper.currency(self.totale_dare - self.totale_avere)
            else
              self.cpt_saldo.label = "Saldo avere:"
              self.lbl_saldo.label = Helpers::ApplicationHelper.currency(self.totale_avere - self.totale_dare)
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
        unless filtro.pdc
            Wx::message_box('Selezionare un conto.',
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
          lku_pdc.activate()
          return
        end

        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_bilancio_partitario,
            :layout => "Landscape",
            :margin_top => 50,
            :margin_bottom => 30,
            :dati_azienda => dati_azienda
          )
          
        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::PrimaNotaHelper::BilancioPartitarioHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        begin
          body.write(
            ERB.new(
              IO.read(Helpers::PrimaNotaHelper::BilancioPartitarioBodyTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
        end

      end

      def render_footer(opts={})
        begin
          footer.write(
            ERB.new(
              IO.read(Helpers::PrimaNotaHelper::BilancioPartitarioFooterTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
        end
      end

      def lstrep_scritture_item_activated(evt)
        if data = evt.get_item().get_data()
          logger.debug("data type: #{data[:type]}")
          logger.debug("data id #{data[:id]}")
          if data[:type] == Models::FatturaClienteScadenzario
            begin
              fattura = ctrl.load_fattura_cliente_scadenzario(data[:id])
              # lancio l'evento per la richiesta di dettaglio fattura
              evt_dettaglio_fattura = Views::Base::CustomEvent::DettaglioFatturaScadenzarioEvent.new(fattura)
              # This sends the event for processing by listeners
              process_event(evt_dettaglio_fattura)
            rescue ActiveRecord::RecordNotFound
              Wx::message_box('Fattura non presente in scadenzario: aggiornare il report.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end
          elsif data[:type] == Models::FatturaFornitore

            begin
              fattura = ctrl.load_fattura_fornitore(data[:id])
              # lancio l'evento per la richiesta di dettaglio fattura
              evt_dettaglio_fattura = Views::Base::CustomEvent::DettaglioFatturaScadenzarioEvent.new(fattura)
              # This sends the event for processing by listeners
              process_event(evt_dettaglio_fattura)
            rescue ActiveRecord::RecordNotFound
              Wx::message_box('Fattura non presente in scadenzario: aggiornare il report.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end
            
          elsif data[:type] == Models::Scrittura

            begin
              scrittura = ctrl.load_scrittura(data[:id])
              # lancio l'evento per la richiesta di dettaglio fattura
              evt_dettaglio_scrittura = Views::Base::CustomEvent::DettaglioScritturaEvent.new(scrittura)
              # This sends the event for processing by listeners
              process_event(evt_dettaglio_scrittura)
            rescue ActiveRecord::RecordNotFound
              Wx::message_box('Scrittura eliminata: aggiornare il report.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end

          elsif data[:type] == Models::Corrispettivo

            begin
              corrispettivo = ctrl.load_corrispettivo(data[:id])
              # lancio l'evento per la richiesta di dettaglio fattura
              evt_dettaglio_corrispettivo = Views::Base::CustomEvent::DettaglioCorrispettivoEvent.new(corrispettivo)
              # This sends the event for processing by listeners
              process_event(evt_dettaglio_corrispettivo)
            rescue ActiveRecord::RecordNotFound
              Wx::message_box('Corrispettivo eliminato: aggiornare il report.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end

          else
            return
          end
        end
      end

      def include_hidden_pdc()
        true
      end

      private

      def reset_totali()
        self.totale_dare = 0.0
        self.totale_avere = 0.0
        lbl_totale_dare.label = ''
        lbl_totale_avere.label = ''
        cpt_saldo.label = 'Saldo:'
        lbl_saldo.label = ''
      end

    end
  end
end
