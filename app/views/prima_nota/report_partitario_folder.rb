# encoding: utf-8

module Views
  module PrimaNota
    module ReportPartitarioFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :active_filter

      def ui
        model :filtro => {:attrs => []}
        controller :prima_nota

        logger.debug('initializing Scritture ReportPartitarioFolder...')
        xrc = Xrc.instance()

        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_scrittura_changed) do |data|
          chce_anno.load_data(data, :select => :last)
        end
       
        xrc.find('chce_partita', self, :extends => ChoiceStringField) do |list|
          list.load_data(Helpers::PrimaNotaHelper::PARTITE, :include_blank => {:label => 'Tutte'}, :select => :first)
        end
          
        xrc.find('chce_causale', self, :extends => ChoiceField) 

        subscribe(:evt_causale_changed) do |data|
          chce_causale.load_data(data, 
            :label => :descrizione, 
            :if => lambda {|causale| causale.attiva?},
            :include_blank => {:label => 'Tutte'},
            :select => :first)

        end

        xrc.find('chce_banca', self, :extends => ChoiceField) 

        subscribe(:evt_banca_changed) do |data|
          chce_banca.load_data(data, 
            :label => :descrizione, 
            :if => lambda {|banca| banca.attiva?},
            :include_blank => {:label => 'Tutte'},
            :select => :first)

        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)
        
        xrc.find('lstrep_scritture', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Tipo', :width => 40, :align => Wx::LIST_FORMAT_CENTRE},
              {:caption => 'Descrizione', :width => 270, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Cassa (D)', :width => 90, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Cassa (A)', :width => 90, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Banca (D)', :width => 90, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Banca (A)', :width => 90, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Fuori Partita (D)', :width => 90, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Fuori Partita (A)', :width => 90, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Causale', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Banca', :width => 150, :align => Wx::LIST_FORMAT_LEFT}])
                                      
          list.data_info([{:attr => :data, :format => :date, :if => lambda {|data| !data.blank? }},
              {:attr => :tipo},
              {:attr => :descrizione},
              {:attr => :cassa_dare, :format => :currency},
              {:attr => :cassa_avere, :format => :currency},
              {:attr => :banca_dare, :format => :currency},
              {:attr => :banca_avere, :format => :currency},
              {:attr => :fuori_partita_dare, :format => :currency},
              {:attr => :fuori_partita_avere, :format => :currency},
              {:attr => lambda {|causale| (causale ? causale.descrizione : '')}},
              {:attr => lambda {|banca| (banca ? banca.descrizione : '')}}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_scadenzario_clienti_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end
        
        subscribe(:evt_scadenzario_fornitori_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end
        
        subscribe(:evt_prima_nota_changed) do |scritture|
          if active_filter
            btn_ricerca_click(nil)
          end
        end
        
        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F5, btn_ricerca.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, btn_stampa.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end
      
      # viene chiamato al cambio folder
      def init_folder()
        txt_dal.activate()
      end
      
      def reset_folder()
        lstrep_scritture.reset()
        result_set_lstrep_scritture.clear()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            reset_folder()
            transfer_filtro_from_view()
            self.result_set_lstrep_scritture = ctrl.report_partitario()
            lstrep_scritture.display_matrix(result_set_lstrep_scritture)
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

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          template = Helpers::PrimaNotaHelper::ScritturePartitarioTemplatePath
#          generate(template)
#          if filtro.stampa_residuo
#            Models::Scrittura.update_all("congelata = 1, data_residuo = '#{Date.today.to_s(:db)}'", "congelata = 0 and azienda_id = #{Models::Azienda.current.id}")
#          end
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#
#        report.add_field :partitario, chce_partita.string_selection
#        report.add_field :banca, chce_banca.string_selection
#        report.add_field :causale, chce_causale.string_selection
#
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_scritture, :header=>true) do |t|
#          t.add_column(:data) {|row| row[0].to_s(:italian_short_date) unless row[0].blank?}
#          t.add_column(:t) {|row| row[1] unless row[1].blank?}
#          t.add_column(:descrizione) {|row| Helpers::ApplicationHelper.truncate(row[2], :length => 35) unless row[2].blank?}
#          t.add_column(:cassa_d) {|row| Helpers::ApplicationHelper.currency(row[3]) unless row[3].blank?}
#          t.add_column(:cassa_a) {|row| Helpers::ApplicationHelper.currency(row[4]) unless row[4].blank?}
#          t.add_column(:banca_d) {|row| Helpers::ApplicationHelper.currency(row[5]) unless row[5].blank?}
#          t.add_column(:banca_a) {|row| Helpers::ApplicationHelper.currency(row[6]) unless row[6].blank?}
#          t.add_column(:fp_d) {|row| Helpers::ApplicationHelper.currency(row[7]) unless row[7].blank?}
#          t.add_column(:fp_a) {|row| Helpers::ApplicationHelper.currency(row[8]) unless row[8].blank?}
#        end
#      end
      
      def lstrep_scritture_item_activated(evt)
        if ident = evt.get_item().get_data()
          begin
            scrittura = ctrl.load_scrittura(ident[:id])
            if scrittura.esterna? # and not scrittura.stornata? le scritture stornate non vengono visualizzate
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
              
            else
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

    end
  end
end
