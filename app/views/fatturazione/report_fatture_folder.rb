# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Fatturazione
    module ReportFattureFolder
      include Views::Base::Folder
      include Views::Base::MultipleSelectionReport
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :totale_imponibile, :totale_iva, :totale_fatture, :ripresa_saldo, :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :fatturazione

        logger.debug('initializing ReportFattureFolder...')
        xrc = Xrc.instance()
        # Anagrafica cliente
        
        xrc.find('chce_anno', self, :extends => ChoiceStringField)
        xrc.find('chce_cliente', self, :extends => ChoiceField) 

        subscribe(:evt_cliente_changed) do |data|
          chce_cliente.load_data(data, 
                  :label => :denominazione, 
                  :if => lambda {|cliente| cliente.attivo? },
                  :include_blank => {:label => 'Tutti'},
                  :select => :first)

        end

        subscribe(:evt_anni_contabili_ns_changed) do |data|
          chce_anno.load_data(data, :select => :last)

        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)
        xrc.find('chk_riepilogo', self, :extends => CheckField)
        xrc.find('lstrep_fatture', self, :extends => MultiSelReportField) do |list|
          width = (configatron.screen.width <= 1024 ? 300 : 500)
          list.column_info([{:caption => 'Cliente', :width => width},
                            {:caption => 'Fattura', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Imponibile', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Totale', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
                                      
          list.data_info([{:attr => :cliente},
                          {:attr => :fattura},
                          {:attr => :data, :format => :date, :if => lambda {|content| content.is_a? Date}},
                          {:attr => :imponibile, :format => :currency},
                          {:attr => :iva, :format => :currency},
                          {:attr => :importo, :format => :currency}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa_report', self)
        xrc.find('btn_stampa_fatture', self)

        xrc.find('lbl_totale_imponibile', self)
        xrc.find('lbl_totale_iva', self)
        xrc.find('lbl_totale_fatture', self)

        map_events(self)
        
        reset_totali()
        
        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_nota_spese_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end

        subscribe(:evt_fattura_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F5, btn_ricerca.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, btn_stampa_report.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end
      
      # viene chiamato al cambio folder
      def init_folder()
        txt_dal.activate()
      end
      
      def reset_folder()
        lstrep_fatture.reset()
        result_set_lstrep_fatture.clear()
        reset_totali()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            reset_totali()
            transfer_filtro_from_view()
            self.result_set_lstrep_fatture = ctrl.report_fatture()
            lstrep_fatture.display_matrix(result_set_lstrep_fatture)
            self.lbl_totale_imponibile.label = Helpers::ApplicationHelper.currency(totale_imponibile)
            self.lbl_totale_iva.label = Helpers::ApplicationHelper.currency(totale_iva)
            self.lbl_totale_fatture.label = Helpers::ApplicationHelper.currency(totale_fatture)
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
      
      def btn_stampa_report_click(evt)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_fatture,
            :margin_top => 40,
            :margin_bottom => 25,
            :dati_azienda => dati_azienda
          )

        end

      end

      def btn_stampa_fatture_click(evt)
        if (fatture = all_valid_selections()).blank?
          Wx::message_box("Per avviare il processo di stampa è necessario selezionare almeno una fattura.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
        else
          notify(:evt_stampa_fatture, fatture.sort)
        end
      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FattureHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FattureBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        footer.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FattureFooterTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          template = Helpers::FatturazioneHelper::FattureTemplatePath
#          generate(template)
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, "Report fatture"
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_fatture, :header=>true) do |t|
#          t.add_column(:cliente) {|row| row[0]}
#          t.add_column(:documento) {|row| row[1]}
#          t.add_column(:data) {|row| (row[2].is_a?(String) ? row[2] : row[2].to_s(:italian_date)) unless row[2].nil?}
#          t.add_column(:imponibile) {|row| Helpers::ApplicationHelper.currency(row[3])}
#          t.add_column(:iva) {|row| Helpers::ApplicationHelper.currency(row[4])}
#          t.add_column(:totale) {|row| Helpers::ApplicationHelper.currency(row[5])}
#        end
#      end
#
#      def render_footer(report, whatever=nil)
#        report.add_field :doc, 'fatture'
#        report.add_field :tot_imp, self.lbl_totale_imponibile.label
#        report.add_field :tot_iva, self.lbl_totale_iva.label
#        report.add_field :tot_doc, self.lbl_totale_fatture.label
#      end
      
      def lstrep_fatture_item_activated(evt)
        if ident = evt.get_item().get_data()
          begin
            fattura = ctrl.load_fattura_cliente(ident[:id])
          rescue ActiveRecord::RecordNotFound
            Wx::message_box("Fattura eliminata: aggiornare il report.",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            
            return
          end
          
          # lancio l'evento per la richiesta di dettaglio fattura
          evt_dettaglio_fattura = Views::Base::CustomEvent::DettaglioFatturaFatturazioneEvent.new(fattura)
          # This sends the event for processing by listeners
          process_event(evt_dettaglio_fattura)
        end
      end

      private
      
      def reset_totali()
        self.totale_imponibile = 0.0
        self.totale_iva = 0.0
        self.totale_fatture = 0.0
        self.lbl_totale_imponibile.label = ''
        self.lbl_totale_iva.label = ''
        self.lbl_totale_fatture.label = ''
      end
    end
  end
end