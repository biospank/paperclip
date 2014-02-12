# encoding: utf-8

module Views
  module Scadenzario
    module ReportVenditeFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :totale_imponibile, :totale_iva

      def ui
        controller :scadenzario

        logger.debug('initializing Scadenzario ReportVenditeFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('lstrep_vendite', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Cliente', :width => 250},
                            {:caption => 'Fattura', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Importo', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Aliquota', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
                            {:caption => 'Norma', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
                            {:caption => 'Imponibile', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva', :width => 80, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :cliente},
                          {:attr => :fattura},
                          {:attr => :data_emissione},
                          {:attr => :importo, :format => :currency},
                          {:attr => :aliquota},
                          {:attr => :norma},
                          {:attr => :imponibile, :format => :currency},
                          {:attr => :iva, :format => :currency}])

        end

        xrc.find('lstrep_iva', self, :extends => ReportField) do |field|
          field.column_info([{:caption => 'Aliquota', :width => 100, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Norma', :width => 100, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Imponibile', :width => 200, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Iva', :width => 200, :align => Wx::LIST_FORMAT_RIGHT},
            ])
          field.data_info([{:attr => :aliquota},
              {:attr => :norma},
              {:attr => :imponibile, :format => :currency},
              {:attr => :iva, :format => :currency},
            ])
        end

        xrc.find('lbl_totale_imponibile', self)
        xrc.find('lbl_totale_iva', self)

        map_events(self)

      end

      def init_folder()
        # noop

      end

      def reset_folder()
        lstrep_vendite.reset()
        lstrep_iva.reset()
        result_set_lstrep_vendite.clear()
        result_set_lstrep_iva.clear()
        reset_totali()
      end

      def ricerca(filtro)
        begin
          reset_totali()
          self.result_set_lstrep_vendite, self.result_set_lstrep_iva = ctrl.report_vendite(filtro)
          lstrep_vendite.display_matrix(result_set_lstrep_vendite)
          lstrep_iva.display_matrix(result_set_lstrep_iva)
          self.lbl_totale_imponibile.label = Helpers::ApplicationHelper.currency(self.totale_imponibile)
          self.lbl_totale_iva.label = Helpers::ApplicationHelper.currency(self.totale_iva)
        rescue Exception => e
          log_error(self, e)
        end
      end

      def stampa(filtro)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          case result_set_lstrep_iva.size
          when 1..3
            margin_bottom = 50
          when 4..5
            margin_bottom = 60
          when 6..7
            margin_bottom = 70
          end

          generate(:report_vendite,
            :margin_top => 40,
            :margin_bottom => margin_bottom,
            :dati_azienda => dati_azienda,
            :filtro => filtro,
            :preview => false
          )

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]
        filtro = opts[:filtro]

        begin
          header.write(
            ERB.new(
              IO.read(Helpers::ScadenzarioHelper::VenditeHeaderTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
        end

      end

      def render_body(opts={})
        begin
          body.write(
            ERB.new(
              IO.read(Helpers::ScadenzarioHelper::VenditeBodyTemplatePath)
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
              IO.read(Helpers::ScadenzarioHelper::VenditeFooterTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
        end
      end

      def lstrep_vendite_item_activated(evt)
        if ident = evt.get_item().get_data()
          begin
            fattura = ctrl.load_fattura_cliente(ident[:id])
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
        self.totale_imponibile = 0.0
        self.totale_iva = 0.0
        self.lbl_totale_imponibile.label = ''
        self.lbl_totale_iva.label = ''
      end
    end
  end
end
