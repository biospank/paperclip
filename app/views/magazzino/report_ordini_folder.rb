# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Magazzino
    module ReportOrdiniFolder
      include Views::Base::Folder
      include Views::Base::MultipleSelectionReport
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :magazzino

        logger.debug('initializing ReportOrdiniFolder...')
        xrc = Xrc.instance()
        # Anagrafica cliente
        
        xrc.find('chce_fornitore', self, :extends => ChoiceField)

        subscribe(:evt_fornitore_changed) do |data|
          chce_fornitore.load_data(data,
                  :label => :denominazione,
                  :if => lambda {|fornitore| fornitore.attivo? },
                  :include_blank => {:label => 'Tutti'},
                  :select => :first)

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

        subscribe(:evt_anni_contabili_ordine_changed) do |data|
          chce_anno.load_data(data, :select => :last)

        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)
        xrc.find('lstrep_ordini', self, :extends => ReportField) do |list|
          width = (configatron.screen.width <= 1024 ? 350 : 500)
          list.column_info([{:caption => 'Fornitore', :width => width},
                            {:caption => 'Numero', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE}])
                                      
          list.data_info([{:attr => :fornitore},
                          {:attr => :num},
                          {:attr => :data, :format => :date}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa_report', self)
        xrc.find('btn_stampa_ordini', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_ordine_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end
        
        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F5, btn_ricerca.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F9, btn_stampa_report.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_pulisci.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end
      
      # viene chiamato al cambio folder
      def init_folder()
        txt_dal.activate()
      end
      
      def reset_folder()
        lstrep_ordini.reset()
        result_set_lstrep_ordini.clear()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            transfer_filtro_from_view()
            self.result_set_lstrep_ordini = ctrl.report_ordini()
            lstrep_ordini.display_matrix(result_set_lstrep_ordini)
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
      
      def btn_stampa_report_click(evt)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda

          generate(:report_ordini,
            :margin_top => 40,
            :footer => false,
            :dati_azienda => dati_azienda
          )

        end

      end

      def btn_stampa_ordini_click(evt)
        if all_selections.blank?
          Wx::message_box("Per avviare il processo di stampa è necessario selezionare almeno un ordine.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
        else
          ordini = []
          all_selections.each do |item|
            ordini << item[:id]
          end
          notify(:evt_stampa_ordini, ordini)
        end
      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::OrdiniHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::OrdiniBodyTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        begin
#          Wx::BusyCursor.busy() do
#            template = Helpers::MagazzinoHelper::ReportOrdiniTemplatePath
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
#        report.add_field :intestazione, ["Report Ordini", (filtro.al.blank? ? '' : "al #{filtro.al.to_s(:italian_date)}")].join(' ')
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_ordini, :header=>true) do |t|
#          t.add_column(:fornitore) {|row| row[0]}
#          t.add_column(:num_ordine) {|row| row[1]}
#          t.add_column(:data_ordine) {|row| row[2].to_s(:italian_date)}
#        end
#      end
      
      def lstrep_ordini_item_activated(evt)
        if ident = evt.get_item().get_data()
          begin
            ordine = ctrl.load_ordine(ident[:id])
          rescue ActiveRecord::RecordNotFound
            Wx::message_box('Ordine eliminato: aggiornare il report.',
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)

            return
          end
          # lancio l'evento per la richiesta di dettaglio ordine
          evt_dettaglio_ordine = Views::Base::CustomEvent::DettaglioOrdineEvent.new(ordine)
          # This sends the event for processing by listeners
          process_event(evt_dettaglio_ordine)
        end
      end

    end
  end
end