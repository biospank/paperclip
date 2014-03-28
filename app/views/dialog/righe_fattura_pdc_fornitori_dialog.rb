# encoding: utf-8

module Views
  module Dialog
    class RigheFatturaPdcFornitoriDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      WX_ID_F2 = Wx::ID_ANY

      attr_accessor :owner,
        :dialog_sql_criteria, # utilizzato nelle dialog
        :importo_fattura,
        :totale_importi
     
      def initialize(parent, righe_fattura_pdc)
        super()
        
        self.owner = parent
        
        model :riga_fattura_pdc => {:attrs => [:aliquota,
          :norma,
          :imponibile,
          :iva,
          :detrazione,
          :pdc]}

        controller :scadenzario

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "RIGHE_FATTURA_PDC_FORNITORI_DLG")

        xrc.find('lku_aliquota', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|aliquota| self.txt_descrizione_aliquota.view_data = (aliquota ? aliquota.descrizione : nil)},
                                :model => :aliquota,
                                :dialog => :aliquote_dialog,
                                :default => lambda {|aliquota| aliquota.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
        end

        xrc.find('txt_descrizione_aliquota', self, :extends => TextField)

        xrc.find('txt_imponibile', self, :extends => DecimalField)
        xrc.find('txt_iva', self, :extends => DecimalField)

        xrc.find('lku_pdc', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
                              )
          if configatron.bilancio.attivo
            enable_widgets([field])
          else
            disable_widgets([field])
          end
        end

        xrc.find('txt_descrizione_pdc', self, :extends => TextField)

        xrc.find('lku_norma', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|norma| self.txt_descrizione_norma.view_data = (norma ? norma.descrizione : nil)},
                                :model => :norma,
                                :dialog => :norma_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
        end

        xrc.find('txt_descrizione_norma', self, :extends => TextField)

        xrc.find('lstrep_righe_fattura_pdc', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Aliquota', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Norma', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Imponibile', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Iva', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Iva indetraibile', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Conto', :width => 150, :align => Wx::LIST_FORMAT_LEFT}
          ])
          list.data_info([{:attr => lambda {|pagamento| (pagamento.aliquota ? pagamento.aliquota.descrizione : '')}},
            {:attr => lambda {|pagamento| (pagamento.norma ? pagamento.norma.descrizione : '')}},
            {:attr => :imponibile, :format => :currency},
            {:attr => :iva, :format => :currency},
            {:attr => :detrazione, :format => :currency},
            {:attr => lambda {|pagamento| (pagamento.pdc ? "#{pagamento.pdc.codice} - #{pagamento.pdc.descrizione}" : '')}}
          ])
        end

        xrc.find('lbl_importo_fattura', self)
        xrc.find('lbl_totale_righe', self)
        xrc.find('lbl_residuo', self)

        self.result_set_lstrep_righe_fattura_pdc = righe_fattura_pdc

        evt_menu(WX_ID_F2) do
          lstrep_righe_fattura_pdc.activate()
        end

        evt_new do | evt |
          case evt.data[:subject]
          when :aliquota
            end_modal(lku_aliquota.get_id)
          when :norma
            end_modal(lku_norma.get_id)
          when :pdc
            end_modal(lku_pdc.get_id)
          end
        end

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)

        map_events(self)

        map_text_enter(self, {'txt_imponibile' => 'on_riga_text_enter',
                              'txt_iva' => 'on_riga_text_enter',
                              'lku_aliquota' => 'on_riga_text_enter',
                              'lku_norma' => 'on_riga_text_enter',
                              'lku_pdc' => 'on_riga_text_enter'})

        lku_aliquota.load_data(ctrl.search_aliquote())

        lku_norma.load_data(ctrl.search_norma())

        lku_pdc.load_data(ctrl.search_pdc())

        init_panel()

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ]
        ]
        self.accelerator_table = acc_table
      end

      def init_panel()
        begin
          display_righe_fattura_pdc()
          riepilogo_importi()
          reset_gestione_riga()
          init_gestione_riga()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def reset_panel()
        begin
          reset_gestione_riga()

          lstrep_righe_fattura_pdc.reset()
          self.result_set_lstrep_righe_fattura_pdc = []

          riepilogo_importi()

        rescue Exception => e
          log_error(self, e)
        end

      end

      def on_riga_text_enter(evt)
        begin
          lku_aliquota.match_selection()
          lku_norma.match_selection()
          lku_pdc.match_selection()
          if(lstrep_righe_fattura_pdc.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            if((self.importo_fattura - self.totale_importi).zero?)
              end_modal(Wx::ID_OK)
            else
              btn_aggiungi_click(evt)
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      # sovrascritto per nascondere il pulsante nuovo nella dialog
      def lku_aliquota_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            dlg = Views::Dialog::AliquoteDialog.new(self, true, false)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_aliquota.view_data = ctrl.load_aliquota(dlg.selected)
              lku_aliquota_after_change()
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_aliquota_after_change()
        begin
          lku_aliquota.match_selection()
          transfer_riga_fattura_pdc_from_view
          calcola_scorporo_residuo(true)
          transfer_riga_fattura_pdc_to_view
        rescue Exception => e
          log_error(self, e)
        end
      end

      def lku_aliquota_loose_focus()
        begin
          lku_aliquota.match_selection()
          transfer_riga_fattura_pdc_from_view
          calcola_scorporo_residuo()
          transfer_riga_fattura_pdc_to_view
        rescue Exception => e
          log_error(self, e)
        end
      end

      # sovrascritto per nascondere il pulsante nuovo nella dialog
      def lku_norma_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            dlg = Views::Dialog::NormaDialog.new(self, true, false)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_norma.view_data = ctrl.load_norma(dlg.selected)
              lku_norma_after_change()
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_norma_after_change()
        begin
          lku_norma.match_selection()
          transfer_riga_fattura_pdc_from_view
          calcola_scorporo_residuo()
          transfer_riga_fattura_pdc_to_view
        rescue Exception => e
          log_error(self, e)
        end
      end

      def lku_norma_loose_focus()
        begin
          lku_norma.match_selection()
          transfer_riga_fattura_pdc_from_view
          calcola_scorporo_residuo()
          transfer_riga_fattura_pdc_to_view
        rescue Exception => e
          log_error(self, e)
        end
      end

      def txt_imponibile_loose_focus()
        begin
          if aliquota = lku_aliquota.view_data
            if imponibile = txt_imponibile.view_data
              if Helpers::ApplicationHelper.real(imponibile) != Helpers::ApplicationHelper.real(self.riga_fattura_pdc.imponibile)
                txt_iva.view_data = ((imponibile * aliquota.percentuale) / 100)
              end
#            else
#              calcola_scorporo_residuo()
            end
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      # sovrascritto per nascondere il pulsante nuovo nella dialog
      # e passare un criterio di ricerca diverso
      def lku_pdc_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.costo_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self, true, false)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_after_change()
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_aggiungi_click(evt)
        begin
          transfer_riga_fattura_pdc_from_view()
          if pdc_compatibile?
            if self.riga_fattura_pdc.valid?
              Wx::BusyCursor.busy() do
                self.result_set_lstrep_righe_fattura_pdc << self.riga_fattura_pdc
                display_righe_fattura_pdc()
                lstrep_righe_fattura_pdc.force_visible(:last)
                riepilogo_importi()
                reset_gestione_riga()
                init_gestione_riga()
                lku_aliquota.activate()
              end
            else
              Wx::message_box(self.riga_fattura_pdc.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_riga_fattura_pdc_error_field()

            end
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)

        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_modifica_click(evt)
        begin
          transfer_riga_fattura_pdc_from_view()
          if pdc_compatibile?
            if self.riga_fattura_pdc.valid?
              Wx::BusyCursor.busy() do
                self.riga_fattura_pdc.log_attr()
                display_righe_fattura_pdc()
                riepilogo_importi()
                reset_gestione_riga()
                init_gestione_riga()
                lku_aliquota.activate()
              end
            else
              Wx::message_box(self.riga_fattura_pdc.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_riga_fattura_pdc_error_field()

            end
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)

        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_elimina_click(evt)
        begin
          transfer_riga_fattura_pdc_from_view()
          Wx::BusyCursor.busy() do
            self.riga_fattura_pdc.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
            display_righe_fattura_pdc()
            riepilogo_importi()
            reset_gestione_riga()
            init_gestione_riga()
            lku_aliquota.activate()
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_nuovo_click(evt)
        begin
          reset_gestione_riga()
          init_gestione_riga()
          # serve ad eliminare l'eventuale focus dalla lista
          # evita che rimanga selezionato un elemento della lista
          lstrep_righe_fattura_pdc.display(self.result_set_lstrep_righe_fattura_pdc)
          lku_aliquota.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def lstrep_righe_fattura_pdc_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_fattura_pdc.each do |record|
            if record.ident() == row_id
              self.riga_fattura_pdc = record
              self.selected = self.riga_fattura_pdc.id
              break
            end
          end
          transfer_riga_fattura_pdc_to_view()
          enable_widgets [btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def display_righe_fattura_pdc()
        lstrep_righe_fattura_pdc.display(self.result_set_lstrep_righe_fattura_pdc)
      end

      def reset_gestione_riga()
        reset_riga_fattura_pdc()
        lku_pdc.view_data = self.owner.fornitore.pdc
        enable_widgets [btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end

      def init_gestione_riga()
        lku_aliquota.set_default()
        lku_pdc.view_data = self.owner.fornitore.pdc
        transfer_riga_fattura_pdc_from_view
        calcola_scorporo_residuo()
        transfer_riga_fattura_pdc_to_view
      end

      def lstrep_righe_fattura_pdc_item_activated(evt)
        lku_aliquota.activate()
      end

      def btn_ok_click(evt)
        Wx::BusyCursor.busy() do
          if righe_pdc_ok?
            if totale_compatibile?
              evt.skip()
            else
              Wx::message_box("Il totale degli importi non corrisponde al totale della fattura.",
                'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
              lku_aliquota.activate()
            end
          else
            Wx::message_box("Righe incomplete: manca il codice conto.",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)

            lku_aliquota.activate()
            evt.skip(false)
          end
        end
      end

      def totale_compatibile?
        totale_righe = 0.0
        self.result_set_lstrep_righe_fattura_pdc.each do |riga|
          if riga.valid_record?
            totale_righe += (riga.imponibile + riga.iva)
          end
        end

        Helpers::ApplicationHelper.real(totale_righe) == Helpers::ApplicationHelper.real(self.owner.fattura_fornitore.importo)
      end

      def righe_pdc_ok?
        ok = true
        begin
          if configatron.bilancio.attivo
            self.result_set_lstrep_righe_fattura_pdc.each do |riga|
              if riga.valid_record?
                unless riga.valid?
                  ok = false
                  break
                end
              end
            end
          end
        rescue Exception => e
          log_error(e)
        end

        ok
      end

      def riepilogo_importi()
        self.totale_importi = 0.0
        self.importo_fattura = owner.fattura_fornitore.importo || 0.0

        self.result_set_lstrep_righe_fattura_pdc.each do |riga|
          if riga.valid_record?
            self.totale_importi += (riga.imponibile + riga.iva)
          end
        end

        self.lbl_residuo.foreground_colour = self.lbl_totale_righe.foreground_colour = ((Helpers::ApplicationHelper.real(self.totale_importi) == Helpers::ApplicationHelper.real(self.importo_fattura)) ? Wx::BLACK : Wx::RED)
        self.lbl_importo_fattura.label = Helpers::ApplicationHelper.currency(self.importo_fattura)
        self.lbl_totale_righe.label = Helpers::ApplicationHelper.currency(self.totale_importi)
        self.lbl_residuo.label = Helpers::ApplicationHelper.currency(self.importo_fattura - self.totale_importi)

      end

      def calcola_scorporo_residuo(force = false)
        if lku_aliquota.view_data
          if force
            residuo = (self.importo_fattura - self.totale_importi)
            if residuo.zero?
              if((importo = (self.riga_fattura_pdc.imponibile + self.riga_fattura_pdc.iva)) > 0)
                self.riga_fattura_pdc.calcola_iva(importo)
                self.riga_fattura_pdc.calcola_imponibile(importo)
              end
            else
              self.riga_fattura_pdc.calcola_iva(residuo)
              self.riga_fattura_pdc.calcola_imponibile(residuo)
            end
          else
            if((residuo = (self.importo_fattura - self.totale_importi)) > 0)
              self.riga_fattura_pdc.calcola_iva(residuo)
              self.riga_fattura_pdc.calcola_imponibile(residuo)
            end
          end
        end
        if lku_norma.view_data
          self.riga_fattura_pdc.calcola_detrazione()
        else
          self.riga_fattura_pdc.detrazione = nil
        end
      end

      def pdc_compatibile?
        if configatron.bilancio.attivo
          if self.riga_fattura_pdc.pdc && self.riga_fattura_pdc.pdc.ricavo?
            res = Wx::message_box("Il piano dei conti selezionato non è un costo.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                lku_pdc.activate()
                return false
              end

          end
        end

        return true
      end

      def costo_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::COSTO}')"
      end
    end
  end
end
