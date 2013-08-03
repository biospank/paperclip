# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Scadenzario
    module ReportScadenzeClientiFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :totale_fatture, :totale_nc, :totale_saldo, :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :scadenzario

        logger.debug('initializing ReportScadenzeClientiFolder...')
        xrc = Xrc.instance()
        
        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_fattura_cliente_changed) do |data|
          chce_anno.load_data(data, :select => :last)

        end

        xrc.find('chce_cliente', self, :extends => ChoiceField) 

        subscribe(:evt_cliente_changed) do |data|
          chce_cliente.load_data(data, 
                  :label => :denominazione, 
                  :if => lambda {|cliente| cliente.attivo? },
                  :include_blank => {:label => 'Tutti'},
                  :select => :first)

        end

        xrc.find('chk_modalita', self, :extends => CheckField)
        xrc.find('chce_tipo_pagamento', self, :extends => ChoiceField) 

        subscribe(:evt_tipo_pagamento_cliente_changed) do |data|
          chce_tipo_pagamento.load_data(data, 
                  :label => :descrizione, 
                  :if => lambda {|tipo_pagamento| tipo_pagamento.attivo? },
                  :include_blank => {:label => 'Nessuna'},
                  :select => :first)

        end

        xrc.find('chce_banca', self, :extends => ChoiceField) 

        subscribe(:evt_banca_changed) do |data|
          chce_banca.load_data(data, 
                  :label => :descrizione, 
                  :if => lambda {|banca| banca.attiva? },
                  :include_blank => {:label => 'Tutte'},
                  :select => :first)

        end

        xrc.find('txt_fattura_num', self, :extends => TextField)
        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)

        xrc.find('lstrep_scadenze', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Cliente', :width => 250},
                            {:caption => 'Fattura', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'N. C.', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Importo', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Incasso', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Modalità', :width => 120, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Banca', :width => 120, :align => Wx::LIST_FORMAT_LEFT},
                            {:caption => 'Note', :width => 120, :align => Wx::LIST_FORMAT_LEFT}])
          
          cell = lambda do |content|
            if content
              if content.is_a? String
                return content
              else
                return content.descrizione
              end
            else
              return ''
            end
          end
          
          list.data_info([{:attr => :cliente},
                          {:attr => :fattura},
                          {:attr => :nota_di_credito},
                          {:attr => :data, :format => :date,
                            :if => lambda {|data| !data.blank? }},
                          {:attr => :importo, :format => :currency},
                          {:attr => :saldo, :format => :currency},
                          {:attr => cell},
                          {:attr => cell},
                          {:attr => :note}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        # totali
        xrc.find('lbl_totale_fatture', self)
        xrc.find('lbl_totale_nc', self)
        xrc.find('lbl_totale_saldo', self)

        map_events(self)
        
        reset_totali()
        
        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_scadenzario_clienti_changed) do
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
        lstrep_scadenze.reset()
        result_set_lstrep_scadenze.clear()
        reset_totali()
      end
      
      # Gestione eventi
      
      def chk_modalita_click(evt)
        if evt.get_event_object().checked?
          enable_widgets [chce_tipo_pagamento]
        else
          chce_tipo_pagamento.view_data = nil
          disable_widgets [chce_tipo_pagamento]
        end
      end
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            reset_totali()
            transfer_filtro_from_view()
            self.result_set_lstrep_scadenze = ctrl.report_scadenze_clienti()
            lstrep_scadenze.display_matrix(result_set_lstrep_scadenze)
            self.lbl_totale_fatture.label = Helpers::ApplicationHelper.currency(totale_fatture)
            self.lbl_totale_nc.label = Helpers::ApplicationHelper.currency(totale_nc)
            self.lbl_totale_saldo.label = Helpers::ApplicationHelper.currency(totale_saldo - totale_nc)
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

          generate(:report_scadenze,
            :margin_top => 40,
            :margin_bottom => 25,
            :dati_azienda => dati_azienda
          )

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]
        categoria = 'Clienti'

        header.write(
          ERB.new(
            IO.read(Helpers::ScadenzarioHelper::ScadenzeHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::ScadenzarioHelper::ScadenzeBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        footer.write(
          ERB.new(
            IO.read(Helpers::ScadenzarioHelper::ScadenzeFooterTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          template = Helpers::ScadenzarioHelper::ScadenzeClientiTemplatePath
#          generate(template)
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, ["Report Scadenze Fatture Clienti", (filtro.al.blank? ? '' : "al #{filtro.al.to_s(:italian_date)}")].join(' ')
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_scadenze, :header=>true) do |t|
#          t.add_column(:cliente) {|row| row[0]}
#          t.add_column(:fattura) {|row| row[1]}
#          t.add_column(:nc) {|row| row[2]}
#          t.add_column(:data) {|row| (row[3].is_a?(String) ? row[3] : row[3].to_s(:italian_date)) unless row[3].nil?}
#          t.add_column(:importo) {|row| Helpers::ApplicationHelper.currency(row[4])}
#          t.add_column(:saldo) {|row| Helpers::ApplicationHelper.currency(row[5])}
#          t.add_column(:modalita) {|row| (row[6].is_a?(String) ? row[6] : row[6].descrizione) unless row[6].nil?}
#          t.add_column(:banca) {|row| row[7].descrizione if row[7]}
#          t.add_column(:note) {|row| row[8]}
#        end
#      end
#
#      def render_footer(report, whatever=nil)
#        report.add_field :tot_fatture, self.lbl_totale_fatture.label
#        report.add_field :tot_nc, self.lbl_totale_nc.label
#        report.add_field :tot_saldo, self.lbl_totale_saldo.label
#      end
      
      def lstrep_scadenze_item_activated(evt)
        if ident = evt.get_item().get_data()
          begin
            fattura = ctrl.load_fattura_cliente(ident[:id])
            unless fattura.da_scadenzario?
              Wx::message_box('Fattura da scadenzare.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end
          rescue ActiveRecord::RecordNotFound
            Wx::message_box('Fattura eliminata: aggiornare il report.',
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            
            return
          end
          
          # lancio l'evento per la richiesta di dettaglio fattura
          evt_dettaglio_fattura = Views::Base::CustomEvent::DettaglioFatturaScadenzarioEvent.new(fattura)
          # This sends the event for processing by listeners
          process_event(evt_dettaglio_fattura)
        end
      end

      private
      
      def reset_totali()
        self.totale_fatture = 0.0
        self.totale_nc = 0.0
        self.totale_saldo = 0.0
        self.lbl_totale_fatture.label = ''
        self.lbl_totale_nc.label = ''
        self.lbl_totale_saldo.label = ''
      end
    end
  end
end