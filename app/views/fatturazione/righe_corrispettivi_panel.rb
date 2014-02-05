# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Fatturazione
    module RigheCorrispettiviPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog

      def ui
        
        model :corrispettivo => {:attrs => [
          :giorno,
          :importo,
          :aliquota,
          :imponibile,
          :iva,
          :pdc_dare,
          :pdc_avere
        ], :alias => :riga_corrispettivo}
        
        controller :fatturazione

        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_giorno', self, :extends => NumericField)
        xrc.find('txt_importo', self, :extends => DecimalField)

        xrc.find('lku_aliquota', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|aliquota| self.txt_descrizione_aliquota.view_data = (aliquota ? aliquota.descrizione : nil)},
                                :model => :aliquota,
                                :dialog => :aliquote_dialog,
                                :default => lambda {|aliquota| aliquota.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
        end

        xrc.find('txt_descrizione_aliquota', self, :extends => TextField)

        xrc.find('txt_imponibile', self, :extends => DecimalField)
        xrc.find('txt_iva', self, :extends => DecimalField)

        xrc.find('lku_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)
                              
        xrc.find('lstrep_righe_corrispettivi', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Giorno', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Importo', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Aliquota', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
                            {:caption => 'Imponibile', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Pdc', :width => 300, :align => Wx::LIST_FORMAT_LEFT}
          ])
          list.data_info([{:attr => :data, :format => :date},
            {:attr => :importo, :format => :currency},
            {:attr => lambda {|corrispettivo| corrispettivo.aliquota.descrizione},
              :if => lambda {|corrispettivo| corrispettivo.aliquota}
            },
            {:attr => :imponibile, :format => :currency},
            {:attr => :iva, :format => :currency},
            {:attr => lambda {|corrispettivo| corrispettivo.pdc_avere.descrizione},
              :if => lambda {|corrispettivo| corrispettivo.pdc_avere}
            }
          ])

        end

        xrc.find('lbl_totale_corrispettivi', self)
        xrc.find('lbl_totale_imponibile', self)
        xrc.find('lbl_totale_iva', self)

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc_avere.load_data(data)
        end

        subscribe(:evt_aliquota_changed) do |data|
          lku_aliquota.load_data(data)
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([lku_pdc_avere]) : disable_widgets([lku_pdc_avere])
        end

        map_events(self)
        map_text_enter(self, {'txt_giorno' => 'on_riga_text_enter',
                              'txt_importo' => 'on_riga_text_enter',
                              'lku_aliquota' => 'on_riga_text_enter',
                              'lku_pdc_avere' => 'on_riga_text_enter'})
                          
      end

      def init_panel()
        begin
          reset_gestione_riga()
          init_gestione_riga()
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def reset_panel()
        begin
          reset_gestione_riga()
          lstrep_righe_corrispettivi.reset()
          self.result_set_lstrep_righe_corrispettivi = []

        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def on_riga_text_enter(evt)
        begin
          lku_aliquota.match_selection()
          lku_pdc_avere.match_selection()
          if(lstrep_righe_corrispettivi.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def txt_importo_loose_focus()
        transfer_riga_corrispettivo_from_view
        if lku_aliquota.match_selection()
          self.riga_corrispettivo.calcola_iva()
          self.riga_corrispettivo.calcola_imponibile()
        end
        transfer_riga_corrispettivo_to_view
      end

      # sovrascritto per agganciare il filtro sul criterio di ricerca
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
                  Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                  Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER
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

      def btn_aggiungi_click(evt)
        begin
          transfer_riga_corrispettivo_from_view()
          if pdc_compatibile?
            unless giorno_duplicato?
              if self.riga_corrispettivo.valid?
                self.riga_corrispettivo.calcola_iva()
                self.riga_corrispettivo.calcola_imponibile()
                self.result_set_lstrep_righe_corrispettivi << self.riga_corrispettivo
                lstrep_righe_corrispettivi.display(self.result_set_lstrep_righe_corrispettivi)
                lstrep_righe_corrispettivi.force_visible(:last)
                riepilogo_corrispettivi()
                reset_gestione_riga()
                init_gestione_riga()
                txt_giorno.activate()
              else
                Wx::message_box(self.riga_corrispettivo.error_msg,
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)

                case self.riga_corrispettivo.error_field()
                when :pdc_dare
                  owner.lku_pdc_dare.activate()
                else
                  focus_riga_corrispettivo_error_field()
                end

              end
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_modifica_click(evt)
        begin
          if corrispettivo_modificabile?
            transfer_riga_corrispettivo_from_view()
            if pdc_compatibile?
              unless giorno_duplicato?
                if self.riga_corrispettivo.valid?
                  self.riga_corrispettivo.calcola_iva()
                  self.riga_corrispettivo.calcola_imponibile()
                  self.riga_corrispettivo.log_attr()
                  lstrep_righe_corrispettivi.display(self.result_set_lstrep_righe_corrispettivi)
                  riepilogo_corrispettivi()
                  reset_gestione_riga()
                  init_gestione_riga()
                  txt_giorno.activate()
                else
                  Wx::message_box(self.riga_corrispettivo.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  case self.riga_corrispettivo.error_field()
                  when :pdc_dare
                    owner.lku_pdc_dare.activate()
                  else
                    focus_riga_corrispettivo_error_field()
                  end

                end
              end
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_elimina_click(evt)
        begin
          unless riga_congelata?
            self.riga_corrispettivo.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
            lstrep_righe_corrispettivi.display(self.result_set_lstrep_righe_corrispettivi)
            riepilogo_corrispettivi()
            reset_gestione_riga()
            init_gestione_riga()
            update_riga_ui()
            txt_giorno.activate()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_nuovo_click(evt)
        begin
          reset_gestione_riga()
          init_gestione_riga()
          txt_giorno.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def lstrep_righe_corrispettivi_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_corrispettivi.each do |record|
            if record.ident() == row_id
              self.riga_corrispettivo = record
              break
            end
          end
          transfer_riga_corrispettivo_to_view()
          update_riga_ui
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_righe_corrispettivi_item_activated(evt)
        txt_giorno.activate()
      end

      def display_righe_corrispettivi(corrispettivi)
        self.result_set_lstrep_righe_corrispettivi = corrispettivi
        lstrep_righe_corrispettivi.display(self.result_set_lstrep_righe_corrispettivi)
        reset_gestione_riga()
      end
      
      def reset_gestione_riga()
        reset_riga_corrispettivo()
        enable_widgets [btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end

      def update_riga_ui()
        if self.riga_corrispettivo.registrato_in_prima_nota?
          disable_widgets [txt_giorno, txt_importo, lku_aliquota,
                          lku_pdc_avere, btn_aggiungi, btn_modifica]
          disable_widgets [lku_pdc_avere] if configatron.bilancio.attivo
          enable_widgets [btn_elimina, btn_nuovo]
        else
          enable_widgets [txt_giorno, txt_importo, lku_aliquota,
                          lku_pdc_avere, btn_modifica, btn_elimina, btn_nuovo]
          enable_widgets [lku_pdc_avere] if configatron.bilancio.attivo
          disable_widgets [btn_aggiungi]
        end
      end

      def init_gestione_riga()
        self.riga_corrispettivo.anno = owner.chce_anno.view_data()
        self.riga_corrispettivo.mese = owner.chce_mese.view_data()
        self.riga_corrispettivo.aliquota = owner.lku_aliquota.view_data()
        self.riga_corrispettivo.pdc_dare = owner.lku_pdc_dare.view_data()
        self.riga_corrispettivo.pdc_avere = owner.lku_pdc_avere.view_data()
        transfer_riga_corrispettivo_to_view()
      end
      
      def changed?
        self.result_set_lstrep_righe_corrispettivi.detect { |riga| riga.touched? }
      end
      
      def riepilogo_corrispettivi()
        totale_corrispettivi = 0.0
        totale_imponibile = 0.0
        totale_iva = 0.0

        self.result_set_lstrep_righe_corrispettivi.each do |corrispettivo|
          if corrispettivo.valid_record?
            totale_corrispettivi += corrispettivo.importo
            totale_imponibile += corrispettivo.imponibile
            totale_iva += corrispettivo.iva
          end
        end

        self.lbl_totale_corrispettivi.label = Helpers::ApplicationHelper.currency(totale_corrispettivi)
        self.lbl_totale_imponibile.label = Helpers::ApplicationHelper.currency(totale_imponibile)
        self.lbl_totale_iva.label = Helpers::ApplicationHelper.currency(totale_iva)

      end

      def giorno_duplicato?
        if configatron.bilancio.attivo
          duplicato = result_set_lstrep_righe_corrispettivi.any? do |corrispettivo|
            (corrispettivo.valid_record?) &&
            (corrispettivo.ident != self.corrispettivo.ident) &&
            (corrispettivo.pdc_avere_id == self.corrispettivo.pdc_avere_id) &&
            (corrispettivo.aliquota_id == self.corrispettivo.aliquota_id) &&
            (corrispettivo.data == self.corrispettivo.data)
          end
        else
          duplicato = result_set_lstrep_righe_corrispettivi.any? do |corrispettivo|
            (corrispettivo.valid_record?) &&
            (corrispettivo.ident != self.corrispettivo.ident) &&
            (corrispettivo.aliquota_id == self.corrispettivo.aliquota_id) &&
            (corrispettivo.data == self.corrispettivo.data)
          end
        end
        
        if duplicato
          Wx::message_box('Giorno già contabilizzato.',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          txt_giorno.activate()

          return true
        end

        return false
      end

      def pdc_compatibile?
        if configatron.bilancio.attivo
          if(self.riga_corrispettivo.pdc_dare && (self.riga_corrispettivo.pdc_dare.conto_economico? || self.riga_corrispettivo.pdc_dare.ricavo?))
            res = Wx::message_box("Il conto in dare non è un conto patrimoniale attivo.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                owner.lku_pdc_dare.activate()
                return false
              end

          end

          if self.riga_corrispettivo.pdc_avere && self.riga_corrispettivo.pdc_avere.costo?
            res = Wx::message_box("Il conto in avere non è un ricavo.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                lku_pdc_avere.activate()
                return false
              end

          end
        end

        return true
      end

      def riga_congelata?
        if self.riga_corrispettivo.congelato?
          res = Wx::message_box("Scrittura già stampata in definitivo.\nConfermi la cancellazione?",
            'Domanda',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

          if res == Wx::YES
            return false
          end
        else
          return false
        end

        return true
      end

      def corrispettivo_modificabile?
        if self.riga_corrispettivo.registrato_in_prima_nota?
          Wx::message_box('Corrispettivo non modificabile.',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          return false
        else
          return true
        end
      end

      def dare_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}')"
      end

      def avere_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::RICAVO}')"
      end

    end
  end
end