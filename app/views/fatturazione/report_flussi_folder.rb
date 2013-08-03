# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Fatturazione
    module ReportFlussiFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :totale_ns, :totale_incassi, :ripresa_saldo, :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :fatturazione

        logger.debug('initializing ReportFlussiFolder...')
        xrc = Xrc.instance()
        # Anagrafica cliente
        
        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_ns_changed) do |data|
          chce_anno.load_data(data, :select => :last)

        end

        xrc.find('lstrep_flussi', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Cliente', :width => 300},
                            {:caption => 'Gennaio', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Febbraio', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Marzo', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Aprile', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Maggio', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Giugno', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Luglio', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Agosto', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Settembre', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Ottobre', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Novembre', :width => 70, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Dicembre', :width => 70, :align => Wx::LIST_FORMAT_CENTRE}])
                                      
          list.data_info([{:attr => :cliente},
                          {:attr => :gennaio},
                          {:attr => :febbraio},
                          {:attr => :marzo},
                          {:attr => :aprile},
                          {:attr => :maggio},
                          {:attr => :giugno},
                          {:attr => :luglio},
                          {:attr => :agosto},
                          {:attr => :settembre},
                          {:attr => :ottobre},
                          {:attr => :novembre},
                          {:attr => :dicembre}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_nota_spese_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end

        subscribe(:evt_fattura_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
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
      # inizializza il numero fattura
      # e gli anni contabili se non sono gia presenti
      def init_folder()
        chce_anno.activate()
      end
      
      def reset_folder()
        lstrep_flussi.reset()
        result_set_lstrep_flussi.clear()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            transfer_filtro_from_view()
            self.result_set_lstrep_flussi = ctrl.report_flussi()
            lstrep_flussi.display_matrix(result_set_lstrep_flussi)
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

          generate(:report_flussi,
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
            IO.read(Helpers::FatturazioneHelper::FlussiHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FlussiBodyTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        Wx::BusyCursor.busy() do
#          template = Helpers::FatturazioneHelper::FlussiTemplatePath
#          generate(template)
#        end
#      end
#
#      def render_header(report, whatever=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :denominazione, dati_azienda.denominazione
#        report.add_field :intestazione, "Report Flussi #{filtro.anno}"
#      end
#
#      def render_body(report, whatever=nil)
#        report.add_table("Report", self.result_set_lstrep_flussi, :header=>true) do |t|
#          t.add_column(:cliente) {|row| row[0]}
#          t.add_column(:gen) {|row| row[1]}
#          t.add_column(:feb) {|row| row[2]}
#          t.add_column(:mar) {|row| row[3]}
#          t.add_column(:apr) {|row| row[4]}
#          t.add_column(:mag) {|row| row[5]}
#          t.add_column(:giu) {|row| row[6]}
#          t.add_column(:lug) {|row| row[7]}
#          t.add_column(:ago) {|row| row[8]}
#          t.add_column(:set) {|row| row[9]}
#          t.add_column(:ott) {|row| row[10]}
#          t.add_column(:nov) {|row| row[11]}
#          t.add_column(:dic) {|row| row[12]}
#        end
#      end
      
    end
  end
end