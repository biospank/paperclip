# encoding: utf-8

require 'app/views/dialog/storico_residui_dialog'
require 'app/views/prima_nota/report_stampe_common_actions'

module Views
  module PrimaNota
    module ReportStampeBilancioFolder
      include Views::PrimaNota::ReportStampeCommonActions

      def ui
        model :filtro => {:attrs => []}
        controller :prima_nota

        logger.debug('initializing Scritture ReportStampeBilancioFolder...')
        xrc = Xrc.instance()

        xrc.find('chce_stampa_residuo', self, :extends => ChoiceBooleanField) do |field|
          field.load_data([['Copia', false], ['Definitiva', true]],
                  :select => :first)
        end

        xrc.find('btn_storico', self)

        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_scrittura_changed) do |data|
          chce_anno.load_data(data, :select => :last)
        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)

       xrc.find('lstrep_scritture', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Tipo', :width => 40, :align => Wx::LIST_FORMAT_CENTRE},
              {:caption => 'Descrizione', :width => 270, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Importo', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Conto Dare', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Conto Avere', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
              {:caption => 'Causale', :width => 150, :align => Wx::LIST_FORMAT_LEFT}])

          list.data_info([{:attr => :data, :format => :date},
              {:attr => :tipo},
              {:attr => :descrizione},
              {:attr => :importo, :format => :currency},
              {:attr => :pdc_dare},
              {:attr => :pdc_avere},
              {:attr => :causale}])

        end

        xrc.find('btn_ricerca', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_stampa', self)

        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_folder()
        end

        subscribe(:evt_scadenzario_clienti_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end

        subscribe(:evt_scadenzario_fornitori_changed) do
          if active_filter
            btn_ricerca_click(nil)
          end
        end

        subscribe(:evt_prima_nota_changed) do |scritture|
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

      def btn_ricerca_click(evt)
        logger.debug("Cliccato sul bottone ricerca!")
        begin
          Wx::BusyCursor.busy() do
            reset_folder()
            transfer_filtro_from_view()
            self.result_set_lstrep_scritture = ctrl.report_scritture_bilancio()
            lstrep_scritture.display_matrix(result_set_lstrep_scritture)
            transfer_filtro_to_view()
            self.active_filter = true
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def btn_storico_click(evt)
        begin
          Wx::BusyCursor.busy() do
            storico_residui_dlg = Views::Dialog::StoricoResiduiDialog.new(self)
            storico_residui_dlg.center_on_screen(Wx::BOTH)
            answer = storico_residui_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_folder()
              transfer_filtro_from_view()
              filtro.data_storico_residuo = storico_residui_dlg.selected
              self.result_set_lstrep_scritture = ctrl.report_scritture_bilancio()
              lstrep_scritture.display_matrix(result_set_lstrep_scritture)
            end

            storico_residui_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]

        header.write(
          ERB.new(
            IO.read(Helpers::PrimaNotaHelper::StampeBilancioHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        body.write(
          ERB.new(
            IO.read(Helpers::PrimaNotaHelper::StampeBilancioBodyTemplatePath)
          ).result(binding)
        )

      end

    end
  end
end
