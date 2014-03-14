# encoding: utf-8

module Views
  module PrimaNota
    module ContoEconomicoFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :filtro, :totale_ricavi, :totale_costi, :utile_esercizio
      
      def ui
        controller :prima_nota

        logger.debug('initializing Bilancio ContoEconomicoFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('lstrep_ricavi', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Conto', :width => 80},
                            {:caption => 'Descrizione', :width => 250},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :conto},
                          {:attr => :descrizione},
                          {:attr => :importo, :format => :currency}])

        end

        xrc.find('lstrep_costi', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Conto', :width => 80},
                            {:caption => 'Descrizione', :width => 250},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :conto},
                          {:attr => :descrizione},
                          {:attr => :importo, :format => :currency}])

        end

        xrc.find('lbl_totale_ricavi', self)
        xrc.find('lbl_totale_costi', self)
        xrc.find('cpt_utile_esercizio_costi', self)
        xrc.find('lbl_utile_esercizio_costi', self)
        xrc.find('cpt_utile_esercizio_ricavi', self)
        xrc.find('lbl_utile_esercizio_ricavi', self)
        xrc.find('lbl_totale_pareggio_costi', self)
        xrc.find('lbl_totale_pareggio_ricavi', self)

        map_events(self)

      end

      def init_folder()
        # noop

      end

      def reset_folder()
        lstrep_ricavi.reset()
        lstrep_costi.reset()
        result_set_lstrep_ricavi.clear()
        result_set_lstrep_costi.clear()
        reset_totali()
      end

      def ricerca(filtro)
        begin
          reset_totali()
          self.filtro = filtro
          self.result_set_lstrep_costi, self.result_set_lstrep_ricavi  = ctrl.report_conto_economico()
          lstrep_costi.display_matrix(result_set_lstrep_costi)
          lstrep_ricavi.display_matrix(result_set_lstrep_ricavi)
          self.lbl_totale_costi.label = Helpers::ApplicationHelper.currency(self.totale_costi)
          self.lbl_totale_ricavi.label = Helpers::ApplicationHelper.currency(self.totale_ricavi)
          if(Helpers::ApplicationHelper.real(self.totale_costi) >= Helpers::ApplicationHelper.real(self.totale_ricavi))
            self.utile_esercizio = self.totale_costi - self.totale_ricavi
            self.cpt_utile_esercizio_ricavi.label = "PERDITA D'ESERCIZIO"
            self.lbl_utile_esercizio_ricavi.label = Helpers::ApplicationHelper.currency(self.utile_esercizio)
            self.lbl_totale_pareggio_costi.label = Helpers::ApplicationHelper.currency(self.totale_costi)
            self.lbl_totale_pareggio_ricavi.label = Helpers::ApplicationHelper.currency(self.totale_costi)
          else
            self.utile_esercizio = self.totale_ricavi - self.totale_costi
            self.cpt_utile_esercizio_costi.label = "UTILE D'ESERCIZIO"
            self.lbl_utile_esercizio_costi.label = Helpers::ApplicationHelper.currency(self.utile_esercizio)
            self.lbl_totale_pareggio_ricavi.label = Helpers::ApplicationHelper.currency(self.totale_ricavi)
            self.lbl_totale_pareggio_costi.label = Helpers::ApplicationHelper.currency(self.totale_ricavi)
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def stampa(filtro)
        self.filtro = filtro
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_acquisti,
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

#      def lstrep_attivita_item_activated(evt)
#        if ident = evt.get_item().get_data()
#          begin
#            fattura = ctrl.load_fattura_fornitore(ident[:id])
#          rescue ActiveRecord::RecordNotFound
#            Wx::message_box('Fattura eliminata: aggiornare il report.',
#              'Info',
#              Wx::OK | Wx::ICON_INFORMATION, self)
#
#            return
#          end
#
#          # lancio l'evento per la richiesta di dettaglio fattura
#          evt_dettaglio_fattura = Views::Base::CustomEvent::DettaglioFatturaScadenzarioEvent.new(fattura)
#          # This sends the event for processing by listeners
#          process_event(evt_dettaglio_fattura)
#        end
#      end

      private

      def reset_totali()
        self.totale_ricavi = 0.0
        self.totale_costi = 0.0
        self.utile_esercizio = 0.0
        self.lbl_totale_ricavi.label = ''
        self.lbl_totale_costi.label = ''
        self.cpt_utile_esercizio_costi.label = ''
        self.lbl_utile_esercizio_costi.label = ''
        self.cpt_utile_esercizio_ricavi.label = ''
        self.lbl_utile_esercizio_ricavi.label = ''
        self.lbl_totale_pareggio_costi.label = ''
        self.lbl_totale_pareggio_ricavi.label = ''
      end
    end
  end
end
