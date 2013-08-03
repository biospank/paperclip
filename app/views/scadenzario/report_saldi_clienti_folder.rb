# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Scadenzario
    module ReportSaldiClientiFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :ripresa_saldo, :totale_saldi, :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :scadenzario

        logger.debug('initializing ReportSaldiClientiFolder...')
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

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)

        xrc.find('lstrep_saldi', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Cliente', :width => 650},
                            {:caption => 'Saldo', :width => 150, :align => Wx::LIST_FORMAT_RIGHT}])
          
          list.data_info([{:attr => :cliente},
                          {:attr => :saldo, :format => :currency}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        # intestazione totali
        xrc.find('cpt_totale_saldi', self)

        # totali
        xrc.find('lbl_totale_saldi', self)

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
        lstrep_saldi.reset()
        result_set_lstrep_saldi.clear()
        reset_totali()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
#        Wx::message_box('Report in lavorazione',
#          'Info',
#          Wx::OK | Wx::ICON_INFORMATION, self)
        begin
          Wx::BusyCursor.busy() do
            reset_totali()
            transfer_filtro_from_view()
            self.result_set_lstrep_saldi = ctrl.report_saldi_clienti()
            lstrep_saldi.display_matrix(result_set_lstrep_saldi)
            self.lbl_totale_saldi.label = Helpers::ApplicationHelper.currency(self.totale_saldi)
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

          generate(:report_saldi,
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
            IO.read(Helpers::ScadenzarioHelper::SaldiHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::ScadenzarioHelper::SaldiBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        footer.write(
          ERB.new(
            IO.read(Helpers::ScadenzarioHelper::SaldiFooterTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          template = Helpers::ScadenzarioHelper::SaldiClientiTemplatePath
#          generate(template)
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, ["Report Saldi Fatture Clienti", (filtro.al.blank? ? '' : "al #{filtro.al.to_s(:italian_date)}")].join(' ')
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_saldi, :header=>true) do |t|
#          t.add_column(:cliente) {|row| row[0]}
#          t.add_column(:saldo) {|row| Helpers::ApplicationHelper.currency(row[1])}
#        end
#      end
#
#      def render_footer(report, whatever=nil)
#        report.add_field :tot_saldi, self.lbl_totale_saldi.label
#      end
      
      private
      
      def reset_totali()
        self.totale_saldi = 0.0
        self.lbl_totale_saldi.label = ''
      end
    end
  end
end