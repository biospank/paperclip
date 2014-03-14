# encoding: utf-8

module Views
  module PrimaNota
    module StatoPatrimonialeFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :filtro, :totale_attivita, :totale_passivita, :utile_esercizio, :perdita_esercizio
      
      def ui
        controller :prima_nota

        logger.debug('initializing Bilancio StatoPatrimonialeFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('lstrep_attivita', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Conto', :width => 80},
                            {:caption => 'Descrizione', :width => 250},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :conto},
                          {:attr => :descrizione},
                          {:attr => :importo, :format => :currency}])

        end

        xrc.find('lstrep_passivita', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Conto', :width => 80},
                            {:caption => 'Descrizione', :width => 250},
                            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])

          list.data_info([{:attr => :conto},
                          {:attr => :descrizione},
                          {:attr => :importo, :format => :currency}])

        end

        xrc.find('lbl_totale_attivo', self)
        xrc.find('lbl_totale_passivo', self)
        xrc.find('cpt_perdita_esercizio', self)
        xrc.find('lbl_perdita_esercizio', self)
        xrc.find('cpt_utile_esercizio', self)
        xrc.find('lbl_utile_esercizio', self)
        xrc.find('lbl_totale_pareggio_attivo', self)
        xrc.find('lbl_totale_pareggio_passivo', self)

        map_events(self)

      end

      def init_folder()
        # noop

      end

      def reset_folder()
        lstrep_attivita.reset()
        lstrep_passivita.reset()
        result_set_lstrep_attivita.clear()
        result_set_lstrep_passivita.clear()
        reset_totali()
      end

      def ricerca(filtro)
        begin
          reset_totali()
          self.filtro = filtro
          self.result_set_lstrep_attivita, self.result_set_lstrep_passivita = ctrl.report_stato_patrimoniale()
          lstrep_attivita.display_matrix(result_set_lstrep_attivita)
          lstrep_passivita.display_matrix(result_set_lstrep_passivita)
          self.lbl_totale_attivo.label = Helpers::ApplicationHelper.currency(self.totale_attivita)
          self.lbl_totale_passivo.label = Helpers::ApplicationHelper.currency(self.totale_passivita)
          if(Helpers::ApplicationHelper.real(self.totale_attivita) >= Helpers::ApplicationHelper.real(self.totale_passivita))
            self.utile_esercizio = self.totale_attivita - self.totale_passivita
            self.cpt_utile_esercizio.label = "UTILE D'ESERCIZIO"
            self.lbl_utile_esercizio.label = Helpers::ApplicationHelper.currency(self.utile_esercizio)
            self.lbl_totale_pareggio_attivo.label = Helpers::ApplicationHelper.currency(self.totale_attivita)
            self.lbl_totale_pareggio_passivo.label = Helpers::ApplicationHelper.currency(self.totale_attivita)
          else
            self.perdita_esercizio = self.totale_passivita - self.totale_attivita
            self.cpt_perdita_esercizio.label = "PERDITA D'ESERCIZIO"
            self.lbl_perdita_esercizio.label = Helpers::ApplicationHelper.currency(self.utile_esercizio)
            self.lbl_totale_pareggio_passivo.label = Helpers::ApplicationHelper.currency(self.totale_passivita)
            self.lbl_totale_pareggio_attivo.label = Helpers::ApplicationHelper.currency(self.totale_passivita)
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
        self.totale_attivita = 0.0
        self.totale_passivita = 0.0
        self.utile_esercizio = 0.0
        self.perdita_esercizio = 0.0
        self.lbl_totale_attivo.label = ''
        self.lbl_totale_passivo.label = ''
        self.cpt_perdita_esercizio.label = ''
        self.lbl_perdita_esercizio.label = ''
        self.cpt_utile_esercizio.label = ''
        self.lbl_utile_esercizio.label = ''
        self.lbl_totale_pareggio_attivo.label = ''
        self.lbl_totale_pareggio_passivo.label = ''
      end
    end
  end
end
