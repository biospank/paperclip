# encoding: utf-8

module Views
  module Scadenzario
    module ReportAcquistiFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :totale_imponibile, :totale_iva, :totale_iva_detraibile, :totale_iva_indetraibile
      
      def ui
        controller :scadenzario

        logger.debug('initializing Scadenzario ReportAcquistiFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('lstrep_acquisti', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Fornitore', :width => 250},
                            {:caption => 'Fattura', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Importo', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Aliquota', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
                            {:caption => 'Imponibile', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva detraibile', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Norma', :width => 150, :align => Wx::LIST_FORMAT_LEFT}])

          list.data_info([{:attr => :fornitore},
                          {:attr => :fattura},
                          {:attr => :data_emissione},
                          {:attr => :importo, :format => :currency},
                          {:attr => :aliquota},
                          {:attr => :imponibile, :format => :currency},
                          {:attr => :iva, :format => :currency},
                          {:attr => :iva_indetraiblile, :format => :currency},
                          {:attr => :norma}])

        end

        xrc.find('lstrep_iva', self, :extends => ReportField) do |field|
          field.column_info([{:caption => 'Aliquota', :width => 180, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Norma', :width => 180, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Imponibile', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Iva', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Iva detraibile', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Iva indetraibile', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}
            ])
          field.data_info([{:attr => :aliquota},
              {:attr => :norma},
              {:attr => :imponibile, :format => :currency},
              {:attr => :iva, :format => :currency},
              {:attr => :iva_detraibile, :format => :currency},
              {:attr => :iva_indetraibile, :format => :currency}
            ])
        end
        
        xrc.find('lbl_totale_imponibile', self)
        xrc.find('lbl_totale_iva', self)
        xrc.find('lbl_totale_iva_detraibile', self)
        xrc.find('lbl_totale_iva_indetraibile', self)

      end

      def init_folder()
        # noop

      end

      def reset_folder()
        lstrep_acquisti.reset()
        lstrep_iva.reset()
        result_set_lstrep_acquisti.clear()
        result_set_lstrep_iva.clear()
        reset_totali()
      end

      def ricerca(filtro)
        begin
          reset_totali()
          self.result_set_lstrep_acquisti, self.result_set_lstrep_iva = ctrl.report_acquisti(filtro)
          lstrep_acquisti.display_matrix(result_set_lstrep_acquisti)
          lstrep_iva.display_matrix(result_set_lstrep_iva)
          self.lbl_totale_imponibile.label = Helpers::ApplicationHelper.currency(self.totale_imponibile)
          self.lbl_totale_iva.label = Helpers::ApplicationHelper.currency(self.totale_iva)
          self.lbl_totale_iva_detraibile.label = Helpers::ApplicationHelper.currency(self.totale_iva_detraibile)
          self.lbl_totale_iva_indetraibile.label = Helpers::ApplicationHelper.currency(self.totale_iva_indetraibile)
        rescue Exception => e
          log_error(self, e)
        end
      end

      def stampa(filtro)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_acquisti,
            :margin_top => 40,
            :margin_bottom => 60,
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
              IO.read(Helpers::ScadenzarioHelper::AcquistiHeaderTemplatePath)
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
              IO.read(Helpers::ScadenzarioHelper::AcquistiBodyTemplatePath)
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
              IO.read(Helpers::ScadenzarioHelper::AcquistiFooterTemplatePath)
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
        self.totale_iva_detraibile = 0.0
        self.totale_iva_indetraibile = 0.0
        self.lbl_totale_imponibile.label = ''
        self.lbl_totale_iva.label = ''
        self.lbl_totale_iva_detraibile.label = ''
        self.lbl_totale_iva_indetraibile.label = ''
      end
    end
  end
end
