# encoding: utf-8

require 'app/views/scadenzario/report_liquidazioni_notebook_mgr'

module Views
  module Scadenzario
    module ReportLiquidazioneIvaFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      def ui
        model :filtro => {:attrs => []}
        controller :scadenzario

        logger.debug('initializing Scadenzario ReportLiquidazioneIvaFolder...')
        xrc = Helpers::WxHelper::Xrc.instance()

        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_fattura_cliente_changed) do |data|
          chce_anno.load_data(data, :select => :last)

        end

        xrc.find('chce_periodo', self, :extends => ChoiceField)

        subscribe(:evt_azienda_changed) do
          init_folder()
        end

        subscribe(:evt_azienda_updated) do
          init_folder()
        end

        xrc.find('btn_calcola', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        xrc.find('REPORT_LIQUIDAZIONI_NOTEBOOK_MGR', self, :extends => Views::Scadenzario::ReportLiquidazioniNotebookMgr)
        report_liquidazioni_notebook_mgr.ui()

        map_events(self)

      # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F5, btn_calcola.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, btn_stampa.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_pulisci.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def init_folder()
        if Models::Azienda.current.dati_azienda.liquidazione_iva == Helpers::ApplicationHelper::Liquidazione::MENSILE
          chce_periodo.load_data(Helpers::ApplicationHelper::MESI,
            :label => :descrizione,
            :select => (Date.today.month - 1))
        else
          chce_periodo.load_data(Helpers::ApplicationHelper::Liquidazione::PERIODO_TRIMESTRE,
            :label => :descrizione,
            :select => Helpers::ApplicationHelper::Liquidazione::RANGE_TO_POSITION[
              Range.new(Date.today.beginning_of_quarter.month, Date.today.end_of_quarter.month)
            ]
          )
        end

        chce_anno.activate()
      end
      
      def reset_folder()
        report_liquidazioni_notebook_mgr.reset_folder
      end

      # Gestione eventi

      def chce_anno_select(evt)
        begin
          Wx::BusyCursor.busy() do
            reset_folder()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def chce_periodo_select(evt)
        begin
          Wx::BusyCursor.busy() do
            reset_folder()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_calcola_click(evt)
        begin
          Wx::BusyCursor.busy() do
            transfer_filtro_from_view()
            report_liquidazioni_notebook_mgr.ricerca(filtro)
            transfer_filtro_to_view()
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def btn_pulisci_click(evt)
        logger.debug("Cliccato sul bottone pulisci!")
        begin
          reset_folder()
          report_liquidazioni_notebook_mgr.reset_folder
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_stampa_click(evt)
        Wx::BusyCursor.busy() do
          report_liquidazioni_notebook_mgr.stampa(filtro)
        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::ScadenzarioHelper::LiquidazioneIvaHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::ScadenzarioHelper::LiquidazioneIvaBodyTemplatePath)
          ).result(binding)
        )

      end

    end
  end
end
