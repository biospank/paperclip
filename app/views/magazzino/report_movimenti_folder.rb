# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Magazzino
    module ReportMovimentiFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :active_filter

      def ui
        model :filtro => {:attrs => []}
        controller :magazzino

        logger.debug('initializing ReportMovimentiFolder...')
        xrc = Xrc.instance()

        xrc.find('chce_movimento', self, :extends => ChoiceStringField) do |field|
          field.load_data([Models::Movimento::CARICO, Models::Movimento::SCARICO],
                :include_blank => {:label => 'Tutti'},
                :select => :first)

        end

        xrc.find('chce_magazzino', self, :extends => ChoiceField)

        subscribe(:evt_dettaglio_magazzino_changed) do |data|
          chce_magazzino.load_data(data,
                  :label => :nome,
                  :if => lambda {|magazzino| magazzino.attivo? },
                  :include_blank => {:label => 'Tutti'},
                  :select => :default,
                  :default => (data.detect { |magazzino| magazzino.predefinito? }) || data.first)

        end

        xrc.find('chce_prodotto', self, :extends => ChoiceField)

        subscribe(:evt_prodotto_changed) do |data|
          chce_prodotto.load_data(data,
                  :label => :descrizione,
                  :if => lambda {|prodotto| prodotto.attivo? },
                  :include_blank => {:label => 'Tutti'},
                  :select => :first)

        end

        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_movimenti_changed) do |data|
          chce_anno.load_data(data, :select => :last)

        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)

        fattura_rif = lambda do |movimento|
          if((movimento.type == Models::Movimento::SCARICO) &&
              (movimento.riga_fattura))
            movimento.riga_fattura.fattura_cliente.num
          else
            ''
          end
        end

        xrc.find('lstrep_movimenti', self, :extends => ReportField) do |list|
          width = (configatron.screen.width <= 1024 ? 250 : 400)
          list.column_info([{:caption => 'Prodotto', :width => width},
                            {:caption => 'Movimento', :width => 80},
                            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Quantità', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Prezzo acq.', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Prezzo ven.', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Fattura', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Note', :width => 200}
                          ])

          list.data_info([{:attr => lambda {|movimento| movimento.prodotto.descrizione}},
                          {:attr => :type},
                          {:attr => :data, :format => :date},
                          {:attr => :qta},
                          {:attr => :prezzo_acquisto, :format => :currency},
                          {:attr => :prezzo_vendita, :format => :currency},
                          {:attr => lambda {|movimento| fattura_rif.call(movimento)}},
                          {:attr => :note}
                        ])

        end

        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        map_events(self)

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
        txt_dal.activate()
      end

      def reset_folder()
        lstrep_movimenti.reset()
        result_set_lstrep_movimenti.clear()
      end

      # Gestione eventi

      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            transfer_filtro_from_view()
            self.result_set_lstrep_movimenti = ctrl.report_movimenti()
            lstrep_movimenti.display(result_set_lstrep_movimenti)
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

          generate(:report_movimenti,
            :margin_top => 40,
            :footer => false,
            :dati_azienda => dati_azienda
          )

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::MovimentiHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        fattura_rif = lambda do |movimento|
          if((movimento.type == Models::Movimento::SCARICO) &&
              (movimento.riga_fattura))
            movimento.riga_fattura.fattura_cliente.num
          else
            ''
          end
        end

        body.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::MovimentiBodyTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        begin
#          Wx::BusyCursor.busy() do
#            template = Helpers::MagazzinoHelper::ReportMovimentiTemplatePath
#            generate(template)
#          end
#        rescue Exception => e
#          log_error(self, e)
#        end
#
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, ["Report Movimenti (#{filtro.movimento}) ", (filtro.al.blank? ? '' : "al #{filtro.al.to_s(:italian_date)}")].join(' ')
#      end
#
#      def render_body(report, whatever=nil)
#        fattura_rif = lambda do |movimento|
#          if((movimento.type == Models::Movimento::SCARICO) &&
#              (movimento.riga_fattura))
#            movimento.riga_fattura.fattura_cliente.num
#          else
#            ''
#          end
#        end
#
#        report.add_table("Report", self.result_set_lstrep_movimenti, :header=> true) do |t|
#          t.add_column(:descrizione) {|movimento| movimento.prodotto.descrizione}
#          t.add_column(:type)
#          t.add_column(:data) {|movimento| movimento.data.to_s(:italian_date)}
#          t.add_column(:qta)
#          t.add_column(:prezzo_acq) {|prodotto| Helpers::ApplicationHelper.currency(prodotto.prezzo_acquisto)}
#          t.add_column(:prezzo_ven) {|prodotto| Helpers::ApplicationHelper.currency(prodotto.prezzo_vendita)}
#          t.add_column(:fattura) {|movimento| fattura_rif.call(movimento)}
#          t.add_column(:note)
#        end
#      end
#
#      def render_footer(report, whatever=nil)
##        report.add_field :tot_magazzino, self.lbl_totale_magazzino.label
#      end

    end
  end
end
