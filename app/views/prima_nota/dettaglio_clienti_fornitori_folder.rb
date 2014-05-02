# encoding: utf-8

module Views
  module PrimaNota
    module DettaglioClientiFornitoriFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :filtro, :totale_clienti, :totale_fornitori
      
      def ui
        controller :prima_nota

        logger.debug('initializing Bilancio DettaglioClientiFornitoriFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('lstrep_clienti', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Conto', :width => 80},
                            {:caption => 'Descrizione', :width => 250},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :conto},
                          {:attr => :descrizione},
                          {:attr => :importo, :format => :currency}])

        end

        xrc.find('lstrep_fornitori', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Conto', :width => 80},
                            {:caption => 'Descrizione', :width => 250},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :conto},
                          {:attr => :descrizione},
                          {:attr => :importo, :format => :currency}])

        end

        xrc.find('lbl_totale_clienti', self)
        xrc.find('lbl_totale_fornitori', self)

        map_events(self)

      end

      def init_folder()
        # noop

      end

      def reset_folder()
        lstrep_clienti.reset()
        lstrep_fornitori.reset()
        result_set_lstrep_clienti.clear()
        result_set_lstrep_fornitori.clear()
        reset_totali()
      end

      def ricerca(filtro)
        begin
          reset_totali()
          self.filtro = filtro
          self.result_set_lstrep_clienti, self.result_set_lstrep_fornitori  = ctrl.report_dettaglio_clienti_fornitori()
          lstrep_clienti.display_matrix(result_set_lstrep_clienti)
          lstrep_fornitori.display_matrix(result_set_lstrep_fornitori)
          self.lbl_totale_clienti.label = Helpers::ApplicationHelper.currency(self.totale_clienti)
          self.lbl_totale_fornitori.label = Helpers::ApplicationHelper.currency(self.totale_fornitori)
        rescue Exception => e
          log_error(self, e)
        end
      end

      def lstrep_clienti_item_activated(evt)
        if data = evt.get_item().get_data()
          if(data[:type] == Models::Pdc)
            begin
              pdc = ctrl.load_pdc(data[:id])
            rescue ActiveRecord::RecordNotFound
              Wx::message_box('Conto inesistente: aggiornare il report.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end

            evt_dettaglio_report_partitario_bilancio = Views::Base::CustomEvent::DettagliorReportPartitarioBilancioEvent.new(pdc, self.filtro)
            # This sends the event for processing by listeners
            process_event(evt_dettaglio_report_partitario_bilancio)
          end
        end
      end

      def lstrep_fornitori_item_activated(evt)
        if data = evt.get_item().get_data()
          if(data[:type] == Models::Pdc)
            begin
              pdc = ctrl.load_pdc(data[:id])
            rescue ActiveRecord::RecordNotFound
              Wx::message_box('Conto inesistente: aggiornare il report.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              return
            end

            evt_dettaglio_report_partitario_bilancio = Views::Base::CustomEvent::DettagliorReportPartitarioBilancioEvent.new(pdc, self.filtro)
            # This sends the event for processing by listeners
            process_event(evt_dettaglio_report_partitario_bilancio)
          end
        end
      end

      def stampa(filtro)
        self.filtro = filtro
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_dettaglio,
            :margin_top => 50,
            :margin_bottom => 40,
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
              IO.read(Helpers::PrimaNotaHelper::BilancioDettaglioHeaderTemplatePath)
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
              IO.read(Helpers::PrimaNotaHelper::BilancioDettaglioBodyTemplatePath)
            ).result(binding)
          )
        rescue Exception => e
          log_error(self, e)
        end
      end

      def render_footer(opts={})
        begin
#          footer.write(
#            ERB.new(
#              IO.read(Helpers::PrimaNotaHelper::BilancioDettaglioFooterTemplatePath)
#            ).result(binding)
#          )
        rescue Exception => e
          log_error(self, e)
        end
      end

      private

      def reset_totali()
        self.totale_clienti = 0.0
        self.totale_fornitori = 0.0
        self.lbl_totale_clienti.label = ''
        self.lbl_totale_fornitori.label = ''
      end
    end
  end
end
