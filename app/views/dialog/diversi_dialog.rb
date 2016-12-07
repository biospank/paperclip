# encoding: utf-8

module Views
  module Dialog
    class DiversiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Modsels
      
      WX_ID_F2 = Wx::ID_ANY

      attr_accessor :owner,
        :dialog_sql_criteria, # utilizzato nelle dialog
        :importo_fattura,
        :totale_importi
      
      def initialize(parent, righe_diversi)
        super()
        
        self.owner = parent
        
        model :riga_diversi => {:attrs => [:importo,
                                          :pdc_dare,
                                          :pdc_avere]}
        
        controller :prima_nota

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "DIVERSI_DLG")

        xrc.find('txt_importo', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_importo_keypress(evt) }
        end

        xrc.find('lku_pdc_dare', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_dare', self, :extends => TextField)

        xrc.find('lku_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)

        # il pdc delle scritture deve caricare anche i conti dei clienti e dei fornitori
        lku_pdc_dare.load_data(Models::Pdc.search(:all,
            :conditions => dare_sql_criteria,
            :joins => :categoria_pdc
          )
        )

        lku_pdc_avere.load_data(Models::Pdc.search(:all,
            :conditions => avere_sql_criteria,
            :joins => :categoria_pdc
          )
        )

        xrc.find('lstrep_righe_diversi', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Importo', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Conto Dare', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Conto Avere', :width => 200, :align => Wx::LIST_FORMAT_LEFT}
          ])
          list.data_info([{:attr => :importo, :format => :currency},
            {:attr => lambda {|scrittura| (scrittura.pdc_dare ? "#{scrittura.pdc_dare.codice} - #{scrittura.pdc_dare.descrizione}" : '')}},
            {:attr => lambda {|scrittura| (scrittura.pdc_avere ? "#{scrittura.pdc_avere.codice} - #{scrittura.pdc_avere.descrizione}" : '')}},
          ])
        end
        
        xrc.find('lbl_totale_dare', self)
        xrc.find('lbl_totale_avere', self)
        xrc.find('lbl_residuo', self)

#        self.result_set_lstrep_righe_diversi = righe_diversi
        
        evt_menu(WX_ID_F2) do
          lstrep_righe_diversi.activate()
        end

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)

        map_events(self)

        map_text_enter(self, {'txt_importo' => 'on_riga_text_enter',
                              'lku_pdc_dare' => 'on_riga_text_enter',
                              'lku_pdc_avere' => 'on_riga_text_enter'})
                          
#        lku_pdc_dare.load_data(ctrl.search_pdc())
#        
#        lku_pdc_avere.load_data(ctrl.search_pdc())

        init_panel()

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_panel()
        begin
          display_righe_diversi()
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
          
          lstrep_righe_diversi.reset()
          self.result_set_lstrep_righe_diversi = []

          riepilogo_importi()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def lku_pdc_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.dare_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc_dare.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_dare_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                  Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER
                ]
              )
              process_event(evt_new)
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_pdc_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.avere_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc_avere.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_avere_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                  Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER
                ]
              )
              process_event(evt_new)
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def on_riga_text_enter(evt)
        begin
          lku_pdc_dare.match_selection()
          lku_pdc_avere.match_selection()
          if(lstrep_righe_diversi.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end


      def btn_aggiungi_click(evt)
        begin
          transfer_riga_diversi_from_view()
          if pdc_compatibile?
            if self.riga_diversi.valid?
              Wx::BusyCursor.busy() do
                self.result_set_lstrep_righe_diversi << self.riga_diversi
                display_righe_diversi()
                lstrep_righe_diversi.force_visible(:last)
                riepilogo_importi()
                reset_gestione_riga()
                init_gestione_riga()
                txt_importo.activate()
              end
            else
              Wx::message_box(self.riga_diversi.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_riga_diversi_error_field()

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
          transfer_riga_diversi_from_view()
          if pdc_compatibile?
            if self.riga_diversi.valid?
              Wx::BusyCursor.busy() do
                self.riga_diversi.log_attr()
                display_righe_diversi()
                riepilogo_importi()
                reset_gestione_riga()
                init_gestione_riga()
                txt_importo.activate()
              end
            else
              Wx::message_box(self.riga_diversi.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_riga_diversi_error_field()

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
          transfer_riga_diversi_from_view()
          Wx::BusyCursor.busy() do
            self.riga_diversi.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
            display_righe_diversi()
            riepilogo_importi()
            reset_gestione_riga()
            init_gestione_riga()
            txt_importo.activate()
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
          lstrep_righe_diversi.display(self.result_set_lstrep_righe_diversi)
          txt_importo.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def lstrep_righe_diversi_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_diversi.each do |record|
            if record.ident() == row_id
              self.riga_diversi = record
              self.selected = self.riga_diversi.id
              logger.debug("Selected: #{self.selected}")
              break
            end
          end
          transfer_riga_diversi_to_view()
          enable_widgets [btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def display_righe_diversi()
        lstrep_righe_diversi.display(self.result_set_lstrep_righe_diversi)
      end
      
      def reset_gestione_riga()
        reset_riga_diversi()
        enable_widgets [btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end
      
      def init_gestione_riga()
        transfer_riga_diversi_to_view
      end

      def lstrep_righe_diversi_item_activated(evt)
        txt_importo.activate()
      end

      def btn_ok_click(evt)
        Wx::BusyCursor.busy() do
          if totale_compatibile?
            ctrl.save_scrittura_diversi()
            evt.skip()
          else
            Wx::message_box("Il totale dare non corrisponde al totale avere.",
              'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
            txt_importo.activate()
          end
        end
      end

      def totale_compatibile?
        totale_righe = 0.0
        self.result_set_lstrep_righe_diversi.each do |riga|
          if riga.valid_record?
            totale_righe += (riga.imponibile + riga.iva)
          end
        end

        Helpers::ApplicationHelper.real(totale_righe) == Helpers::ApplicationHelper.real(self.owner.fattura_cliente.importo)
      end
      
      def riepilogo_importi()
        self.totale_dare = 0.0
        self.totale_avere = 0.0
        self.importo_fattura = owner.fattura_cliente.importo || 0.0

        self.result_set_lstrep_righe_diversi.each do |riga|
          if riga.valid_record?
            self.totale_importi += (riga.imponibile + riga.iva)
          end
        end

        self.lbl_residuo.foreground_colour = self.lbl_totale_righe.foreground_colour = ((Helpers::ApplicationHelper.real(self.totale_importi) == Helpers::ApplicationHelper.real(self.importo_fattura)) ? Wx::BLACK : Wx::RED)
        self.lbl_importo_fattura.label = Helpers::ApplicationHelper.currency(self.importo_fattura)
        self.lbl_totale_righe.label = Helpers::ApplicationHelper.currency(self.totale_importi)
        self.lbl_residuo.label = Helpers::ApplicationHelper.currency(self.importo_fattura - self.totale_importi)

      end

      def dare_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::COSTO}')"
      end

      def avere_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::RICAVO}')"
      end

      def include_hidden_pdc()
        true
      end

    end
  end
end
