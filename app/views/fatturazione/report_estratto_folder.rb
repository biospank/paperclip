# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Fatturazione
    module ReportEstrattoFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :totale_ns, :totale_incassi, :ripresa_saldo, :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :fatturazione

        logger.debug('initializing ReportEstrattoFolder...')
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
        xrc.find('lstrep_estratto', self, :extends => ReportField) do |list|
          width = (configatron.screen.width <= 1024 ? 350 : 500)
          list.column_info([{:caption => 'Cliente', :width => width},
                            {:caption => Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i], :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Fattura', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Fatturato', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
                                      
          list.data_info([{:attr => :cliente},
                          {:attr => :avviso_fattura},
                          {:attr => :fattura},
                          {:attr => :data, :format => :date, :if => lambda {|content| content.is_a? Date}},
                          {:attr => :importo, :format => :currency},
                          {:attr => :fatturato, :format => :currency}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        # totali
        xrc.find('cpt_totale_ns', self) do |cpt|
          cpt.label = 'Totale ' + Models::NotaSpese::INTESTAZIONE_PLURALE[configatron.pre_fattura.intestazione.to_i].downcase + ':'
        end

        xrc.find('lbl_totale_ns', self)
        xrc.find('lbl_totale_incassi', self)
        xrc.find('lbl_ripresa_saldo', self)
        xrc.find('lbl_totale_saldo', self)

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
        lstrep_estratto.reset()
        result_set_lstrep_estratto.clear()
        reset_totali()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            reset_totali()
            transfer_filtro_from_view()
            self.result_set_lstrep_estratto = ctrl.report_estratto()
            lstrep_estratto.display_matrix(result_set_lstrep_estratto)
            self.lbl_totale_ns.label = Helpers::ApplicationHelper.currency(totale_ns)
            self.lbl_totale_incassi.label = Helpers::ApplicationHelper.currency(totale_incassi)
            self.lbl_ripresa_saldo.label = Helpers::ApplicationHelper.currency(ripresa_saldo)
            self.lbl_totale_saldo.label = Helpers::ApplicationHelper.currency(totale_ns - totale_incassi)
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

          generate(:report_estratto,
            :margin_top => 40,
            :margin_bottom => 25,
            :dati_azienda => dati_azienda
          )

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::EstrattoHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::EstrattoBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        footer.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::EstrattoFooterTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          template = Helpers::FatturazioneHelper::EstrattoTemplatePath
#          generate(template)
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, ["Report Estratto Fatture", (filtro.al.blank? ? '' : "al #{filtro.al.to_s(:italian_date)}")].join(' ')
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_estratto, :header=>true) do |t|
#          t.add_column(:cliente) {|row| row[0]}
#          t.add_column(:documento) {|row| row[1]}
#          t.add_column(:fattura) {|row| row[2]}
#          t.add_column(:data) {|row| (row[3].is_a?(String) ? row[3] : row[3].to_s(:italian_date)) unless row[3].nil?}
#          t.add_column(:importo) {|row| Helpers::ApplicationHelper.currency(row[4])}
#          t.add_column(:fatturato) {|row| Helpers::ApplicationHelper.currency(row[5])}
#        end
#      end
#
#      def render_footer(report, whatever=nil)
#        report.add_field :doc, Models::NotaSpese::INTESTAZIONE_PLURALE[configatron.pre_fattura.intestazione.to_i].downcase
#        report.add_field :tot_doc, self.lbl_totale_ns.label
#        report.add_field :tot_incassi, self.lbl_totale_incassi.label
#        report.add_field :ripresa_saldo, self.lbl_ripresa_saldo.label
#        report.add_field :tot_saldo, self.lbl_totale_saldo.label
#      end
      
      def lstrep_estratto_item_activated(evt)
        if ident = evt.get_item().get_data()
          if ident[:type] == Models::FatturaClienteFatturazione
            begin
              fattura = ctrl.load_fattura_cliente(ident[:id])
            rescue ActiveRecord::RecordNotFound
              Wx::message_box('Fattura eliminata: aggiornare il report.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end
            # lancio l'evento per la richiesta di dettaglio fattura
            evt_dettaglio_fattura = Views::Base::CustomEvent::DettaglioFatturaFatturazioneEvent.new(fattura)
            # This sends the event for processing by listeners
            process_event(evt_dettaglio_fattura)
          elsif ident[:type] == Models::NotaSpese
            begin
              nota_spese = ctrl.load_nota_spese(ident[:id])
            rescue ActiveRecord::RecordNotFound
              Wx::message_box("#{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} eliminata: aggiornare il report.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end
            # lancio l'evento per la richiesta di dettaglio fattura
            evt_dettaglio_nota_spese = Views::Base::CustomEvent::DettaglioNotaSpeseEvent.new(nota_spese)
            # This sends the event for processing by listeners
            process_event(evt_dettaglio_nota_spese)
          end 
        end
      end

      private
      
      def reset_totali()
        self.totale_ns = 0.0
        self.totale_incassi = 0.0
        self.ripresa_saldo = 0.0
        self.lbl_totale_ns.label = ''
        self.lbl_totale_incassi.label = ''
        self.lbl_ripresa_saldo.label = ''
        self.lbl_totale_saldo.label = ''
      end
    end
  end
end