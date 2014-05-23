# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/fatturazione/righe_corrispettivi_common_actions'

module Views
  module Fatturazione
    module RigheCorrispettiviPanel
      include Views::Fatturazione::RigheCorrispettiviCommonActions

      def ui

        model :corrispettivo => {:attrs => [
          :giorno,
          :importo,
          :aliquota,
          :imponibile,
          :iva,
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

        xrc.find('lstrep_righe_corrispettivi', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Giorno', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Importo', :width => 150, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Aliquota', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
                            {:caption => 'Imponibile', :width => 150, :align => Wx::LIST_FORMAT_RIGHT},
                            {:caption => 'Iva', :width => 150, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => :data, :format => :date},
            {:attr => :importo, :format => :currency},
            {:attr => lambda {|corrispettivo| corrispettivo.aliquota.descrizione},
              :if => lambda {|corrispettivo| corrispettivo.aliquota}
            },
            {:attr => :imponibile, :format => :currency},
            {:attr => :iva, :format => :currency}
          ])

        end

        xrc.find('lbl_totale_corrispettivi', self)
        xrc.find('lbl_totale_imponibile', self)
        xrc.find('lbl_totale_iva', self)

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        subscribe(:evt_aliquota_changed) do |data|
          lku_aliquota.load_data(data)
        end

        map_events(self)
        map_text_enter(self, {'txt_giorno' => 'on_riga_text_enter',
                              'txt_importo' => 'on_riga_text_enter',
                              'lku_aliquota' => 'on_riga_text_enter'})

      end

      def on_riga_text_enter(evt)
        begin
          lku_aliquota.match_selection()
          if(lstrep_righe_corrispettivi.get_selected_item_count() > 0)
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
          transfer_riga_corrispettivo_from_view()
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

              focus_riga_corrispettivo_error_field()

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

                focus_riga_corrispettivo_error_field()

              end
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def update_riga_ui()
        if self.riga_corrispettivo.registrato_in_prima_nota?
          disable_widgets [txt_giorno, txt_importo, lku_aliquota,
                          btn_aggiungi, btn_modifica]
          enable_widgets [btn_elimina, btn_nuovo]
        else
          enable_widgets [txt_giorno, txt_importo, lku_aliquota,
                          btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
        end
      end

      def init_gestione_riga()
        self.riga_corrispettivo.anno = owner.chce_anno.view_data()
        self.riga_corrispettivo.mese = owner.chce_mese.view_data()
        self.riga_corrispettivo.aliquota = owner.lku_aliquota.view_data()
        transfer_riga_corrispettivo_to_view()
      end

      def giorno_duplicato?
        duplicato = result_set_lstrep_righe_corrispettivi.any? do |corrispettivo|
          (corrispettivo.valid_record?) &&
          (corrispettivo.ident != self.corrispettivo.ident) &&
          (corrispettivo.aliquota_id == self.corrispettivo.aliquota_id) &&
          (corrispettivo.data == self.corrispettivo.data)
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

    end
  end
end
