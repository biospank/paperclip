# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Magazzino
    module ReportGiacenzeFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :totale_magazzino, :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :magazzino

        logger.debug('initializing ReportGiacenzeFolder...')
        xrc = Xrc.instance()
        # Anagrafica cliente
        
        xrc.find('chce_prodotto', self, :extends => ChoiceField)

        subscribe(:evt_prodotto_changed) do |data|
          chce_prodotto.load_data(data,
                  :label => :descrizione,
                  :if => lambda {|prodotto| prodotto.attivo? },
                  :include_blank => {:label => 'Tutti'},
                  :select => :first)

        end

        xrc.find('txt_al', self, :extends => DateField) do |field|
          field.view_data = Date.today
        end

        width = (configatron.screen.width <= 1024 ? 300 : 400)

        xrc.find('lstrep_giacenze', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Codice', :width => 80},
                            {:caption => 'Prodotto', :width => width},
                            {:caption => 'Qta', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Prezzo Unit.', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Totale', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
                                      
          list.data_info([{:attr => :codice},
                          {:attr => :descrizione},
                          {:attr => :qta},
                          {:attr => :prezzo_acquisto, :format => :currency},
                          {:attr => lambda {|prodotto| (prodotto.qta.to_i * prodotto.prezzo_acquisto.to_f)}, :format => :currency}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        xrc.find('lbl_totale_magazzino', self)

        reset_totali()
        
        map_events(self)
        
        subscribe(:evt_magazzino_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end

        subscribe(:evt_azienda_changed) do
          reset_folder()
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
        txt_al.view_data ||= Date.today
        txt_al.activate()
      end
      
      def reset_folder()
        lstrep_giacenze.reset()
        result_set_lstrep_giacenze.clear()
        reset_totali()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            reset_totali()
            transfer_filtro_from_view()
            self.result_set_lstrep_giacenze = ctrl.report_giacenze()
            lstrep_giacenze.display(result_set_lstrep_giacenze)
            self.lbl_totale_magazzino.label = Helpers::ApplicationHelper.currency(totale_magazzino)
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

          generate(:report_giacenze,
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
            IO.read(Helpers::MagazzinoHelper::GiacenzeHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::GiacenzeBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        footer.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::GiacenzeFooterTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          template = Helpers::MagazzinoHelper::ReportGiacenzeTemplatePath
#          generate(template)
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, ["Report Giacenze Magazzino", (filtro.al.blank? ? '' : "al #{filtro.al.to_s(:italian_date)}")].join(' ')
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_giacenze, :header=> true) do |t|
#          t.add_column(:codice)
#          t.add_column(:descrizione)
#          t.add_column(:qta)
#          t.add_column(:prezzo_unitario) {|prodotto| Helpers::ApplicationHelper.currency(prodotto.prezzo_acquisto)}
#          t.add_column(:totale) {|prodotto| Helpers::ApplicationHelper.currency((prodotto.qta.to_i * prodotto.prezzo_acquisto.to_f))}
#        end
#      end
#
#      def render_footer(report, whatever=nil)
#        report.add_field :tot_magazzino, self.lbl_totale_magazzino.label
#      end
      
      def reset_totali()
        self.totale_magazzino = 0.0
        self.lbl_totale_magazzino.label = ''
      end
    end
  end
end