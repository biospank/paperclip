# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Fatturazione
    module ReportCorrispettiviFolder
      include Views::Base::Folder
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :totale_corrispettivi, :hash_aliquote_corrispettivi, :active_filter
      
      def ui
        model :filtro => {:attrs => []}
        controller :fatturazione

        logger.debug('initializing ReportCorrispettiviFolder...')
        xrc = Xrc.instance()
        
        xrc.find('chce_corrispettivi', self, :extends => ChoiceField) do |field|
          field.load_data([{:id => 1, :descrizione => 'Corrispettivi'},
                            {:id => 2, :descrizione => 'Dettaglio Iva'}],
                  :label => :descrizione,
                  :select => :first)
        end

        xrc.find('chce_anno', self, :extends => ChoiceStringField) do |chce|
          # carico gli anni contabili
          chce.load_data(ctrl.load_anni_contabili(Models::Corrispettivo, 'data'),
            :select => :last)
        end

        subscribe(:evt_anni_contabili_corrispettivi_changed) do |data|
          chce_anno.load_data(data,
            :select => :last)
        end

        xrc.find('chce_mese', self, :extends => ChoiceField) do |chce|
          chce.load_data(Helpers::ApplicationHelper::MESI,
            :label => :descrizione,
            :select => (Date.today.month - 1))
        end

        xrc.find('chce_aliquota', self, :extends => ChoiceField)
        
        subscribe(:evt_aliquota_changed) do |data|
          chce_aliquota.load_data(data,
                  :label => :descrizione,
                  :include_blank => {:label => 'Tutte'},
                  :if => lambda {|aliquota| aliquota.attiva?},
                  :select => :default,
                  :default => data.detect { |aliquota| aliquota.predefinita? })
        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)

        xrc.find('lstrep_corrispettivi', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Totale', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Imponibile', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
                                      
          list.data_info([{:attr => :data},
                          {:attr => :importo, :format => :currency},
                          {:attr => :imponibile, :format => :currency},
                          {:attr => :iva, :format => :currency}])
          
        end
        
        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        xrc.find('lbl_totale_corrispettivi', self)
        xrc.find('lbl_totale_imponibile_iva', self)

        map_events(self)
        
        reset_totali()
        
        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_corrispettivi_changed) do # NOTA
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
      def init_folder()
        txt_dal.activate()
      end
      
      def reset_folder()
        lstrep_corrispettivi.reset()
        result_set_lstrep_corrispettivi.clear()
        reset_totali()
      end
      
      # Gestione eventi
      
      def btn_ricerca_click(evt)
        begin
          Wx::BusyCursor.busy() do
            reset_totali()
            transfer_filtro_from_view()

            self.result_set_lstrep_corrispettivi, 
            self.hash_aliquote_corrispettivi,
            self.totale_corrispettivi = ctrl.report_corrispettivi()

            update_lstrep_corrispettivi_layout()
            
            lstrep_corrispettivi.display_matrix(result_set_lstrep_corrispettivi)

            transfer_filtro_to_view()
            self.active_filter = true
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def btn_pulisci_click(evt)
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

          aliquote = Models::Aliquota.find(self.hash_aliquote_corrispettivi.keys.sort)


          generate(:report_corrispettivi,
            :margin_top => 40,
            :margin_bottom => 25,
            :dati_azienda => dati_azienda,
            :aliquote => aliquote
          )

        end

      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]
        aliquote = opts[:aliquote]

        header.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::CorrispettiviHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        aliquote = opts[:aliquote]

        body.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::CorrispettiviBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        aliquote = opts[:aliquote]

        footer.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::CorrispettiviFooterTemplatePath)
          ).result(binding)
        )

      end

      private
      
      def reset_totali()
        self.totale_corrispettivi = 0.0
        self.hash_aliquote_corrispettivi = {}
        self.lbl_totale_corrispettivi.label = ''
        self.lbl_totale_imponibile_iva.label = ''
      end

      def update_lstrep_corrispettivi_layout()

        aliquote = Models::Aliquota.find(self.hash_aliquote_corrispettivi.keys.sort)

        columns = [{:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
                   {:caption => 'Totale corrispettivi', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}]

        data = [{:attr => :data},
                {:attr => :importo, :format => :currency}]

        if filtro.corrispettivi == 1
          totale_corrispettivi_iva_label = []

          aliquote.each do |aliquota|
            columns.concat([{:caption => "Corrispettivi (#{aliquota.percentuale}%)", :width => 150, :align => Wx::LIST_FORMAT_RIGHT}])
            data.concat([{:attr => :importo, :format => :currency}])
            totale_corrispettivi_iva_label << "Totale corrispettivi (#{Helpers::ApplicationHelper.percentage(aliquota.percentuale)}): #{Helpers::ApplicationHelper.currency(self.hash_aliquote_corrispettivi[aliquota.id].sum(&:importo))}"
          end

          lstrep_corrispettivi.column_info(columns)

          lstrep_corrispettivi.data_info(data)

          self.lbl_totale_corrispettivi.label = Helpers::ApplicationHelper.currency(self.totale_corrispettivi)

          self.lbl_totale_imponibile_iva.label = totale_corrispettivi_iva_label.join(' -- ')
        else
          totale_imponibile_iva_label = []

          aliquote.each do |aliquota|
            columns.concat([{:caption => "Imponibile (#{aliquota.percentuale}%)", :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => "Iva (#{aliquota.percentuale}%)", :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
            data.concat([{:attr => :imponibile, :format => :currency},
                         {:attr => :iva, :format => :currency}])
            totale_imponibile_iva_label << "Totale imponibile (#{Helpers::ApplicationHelper.percentage(aliquota.percentuale)}): #{Helpers::ApplicationHelper.currency(self.hash_aliquote_corrispettivi[aliquota.id].sum(&:imponibile))} - Totale iva (#{Helpers::ApplicationHelper.percentage(aliquota.percentuale)}): #{Helpers::ApplicationHelper.currency(self.hash_aliquote_corrispettivi[aliquota.id].sum(&:iva))}"
          end

          lstrep_corrispettivi.column_info(columns)

          lstrep_corrispettivi.data_info(data)

          self.lbl_totale_corrispettivi.label = Helpers::ApplicationHelper.currency(self.totale_corrispettivi)

          self.lbl_totale_imponibile_iva.label = totale_imponibile_iva_label.join(' -- ')
        end

      end
    end
  end
end