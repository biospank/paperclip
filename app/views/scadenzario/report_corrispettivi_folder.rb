# encoding: utf-8

module Views
  module Scadenzario
    module ReportCorrispettiviFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :totale_imponibile, :totale_iva

      def ui
        controller :scadenzario

        logger.debug('initializing Scadenzario ReportCorrispettiviFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('lstrep_corrispettivi', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Aliquota', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
                            {:caption => 'Imponibile', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :data},
                          {:attr => :importo, :format => :currency},
                          {:attr => :aliquota},
                          {:attr => :imponibile, :format => :currency},
                          {:attr => :iva, :format => :currency}])

        end

        xrc.find('lstrep_iva', self, :extends => ReportField) do |field|
          field.column_info([{:caption => 'Aliquota', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Imponibile', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Iva', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            ])
          field.data_info([{:attr => :aliquota},
              {:attr => :imponibile, :format => :currency},
              {:attr => :iva, :format => :currency},
            ])
        end

        xrc.find('lbl_totale_imponibile', self)
        xrc.find('lbl_totale_iva', self)

      end

      def init_folder()
        # noop

      end

      def reset_folder()
        lstrep_corrispettivi.reset()
        lstrep_iva.reset()
        result_set_lstrep_corrispettivi.clear()
        result_set_lstrep_iva.clear()
        reset_totali()
      end

      def ricerca(filtro)
        begin
          reset_totali()
          self.result_set_lstrep_corrispettivi, self.result_set_lstrep_iva = ctrl.report_corrispettivi(filtro)
          lstrep_corrispettivi.display_matrix(result_set_lstrep_corrispettivi)
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

          generate(:report_corrispettivi,
            :margin_top => 40,
            :margin_bottom => 50,
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
              IO.read(Helpers::ScadenzarioHelper::CorrispettiviHeaderTemplatePath)
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
              IO.read(Helpers::ScadenzarioHelper::CorrispettiviBodyTemplatePath)
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
              IO.read(Helpers::ScadenzarioHelper::CorrispettiviFooterTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
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
