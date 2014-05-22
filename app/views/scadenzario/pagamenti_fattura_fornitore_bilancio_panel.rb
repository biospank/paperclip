# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/maxi_pagamenti_dialog'
require 'app/views/scadenzario/pagamenti_fattura_fornitore_common_actions'

module Views
  module Scadenzario
    module PagamentiFatturaFornitoreBilancioPanel
      include Views::Scadenzario::PagamentiFatturaFornitoreCommonActions

      # @overwrite
      def ui

        model :pagamento_fattura_fornitore => {:attrs => [:importo,
          :tipo_pagamento,
          :data_pagamento,
          :note,
          :maxi_pagamento_fornitore],
          :alias => :pagamento_fattura}

        controller :scadenzario

        xrc = Xrc.instance()

        xrc.find('txt_importo', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_importo_keypress(evt) }
        end
        xrc.find('lku_tipo_pagamento', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|tipo_pagamento| self.txt_descrizione_tipo_pagamento.view_data = (tipo_pagamento ? tipo_pagamento.descrizione : nil)},
                                :model => :tipo_pagamento,
                                :dialog => :tipi_pagamento_dialog,
                                :default => lambda {|tipo_pagamento| tipo_pagamento.predefinito?},
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
        end

        subscribe(:evt_tipo_pagamento_fornitore_changed) do |data|
          lku_tipo_pagamento.load_data(data)
        end

        xrc.find('txt_descrizione_tipo_pagamento', self, :extends => TextField)

        xrc.find('txt_data_pagamento', self, :extends => DateField)
        xrc.find('txt_note', self, :extends => TextField)

        xrc.find('tglbtn_maxi_pagamento_fornitore', self, :extends => ToggleLookupField)

        xrc.find('lstrep_pagamenti_fattura', self, :extends => EditableReportField) do |list|
          width = (configatron.screen.width <= 1024 ? 300 : 500)
          list.column_info([{:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Tipo', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Data', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Note', :width => width, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'P', :width => 50, :align => Wx::LIST_FORMAT_CENTRE},
          ])
          list.data_info([{:attr => :importo, :format => :currency},
            {:attr => lambda {|pagamento| (pagamento.tipo_pagamento ? pagamento.tipo_pagamento.descrizione : '')}},
            {:attr => :data_pagamento, :format => :date},
            {:attr => :note},
            {:attr => lambda {|pagamento| (pagamento.registrato_in_prima_nota? ? '@' : '')}}
          ])
        end

        xrc.find('lbl_totale_pagamenti', self)
        xrc.find('lbl_residuo', self)

        xrc.find('lstrep_fonte_pagamenti_fattura', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Tipo', :width => 100, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Note', :width => 160, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Residuo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => :importo, :format => :currency},
            {:attr => lambda {|pagamento| (pagamento.tipo_pagamento ? pagamento.tipo_pagamento.descrizione : '')}},
            {:attr => :note},
            {:attr => :data_pagamento, :format => :date},
            {:attr => lambda {|pagamento| (pagamento.residuo)}, :format => :currency}
          ])
        end

        xrc.find('lstrep_fatture_collegate', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Fornitore', :width => 180},
            {:caption => 'Fattura', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Parziale', :width => 80, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => lambda {|pagamento| pagamento.fattura_fornitore.fornitore.denominazione}},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.num}},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.data_emissione}, :format => :date},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.importo}, :format => :currency},
            {:attr => lambda {|pagamento| (pagamento.importo)}, :format => :currency}
          ])
        end

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        map_events(self)

        map_text_enter(self, {'txt_importo' => 'on_riga_text_enter',
                              'txt_data_pagamento' => 'on_riga_text_enter',
                              'lku_tipo_pagamento' => 'on_riga_text_enter',
                              'txt_note' => 'on_riga_text_enter'})

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F11, tglbtn_maxi_pagamento_fornitore.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      # @overwrite
      def lku_tipo_pagamento_after_change()
        begin
          lku_tipo_pagamento.match_selection()
        rescue Exception => e
          log_error(self, e)
        end

      end

      # @overwrite
      def lku_tipo_pagamento_loose_focus()
        begin
          lku_tipo_pagamento.match_selection()
        rescue Exception => e
          log_error(self, e)
        end

      end

      # @overwrite
      def on_riga_text_enter(evt)
        begin
          lku_tipo_pagamento.match_selection()
          if(lstrep_pagamenti_fattura.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def tglbtn_maxi_pagamento_fornitore_click(evt)
        begin
          if pagamento_modificabile?
            # se il pulsante e' selezionato
            if evt.get_event_object().get_value() or
                pagamento_fattura.new_record?
              # accedo alla gestione dei maxi pagamenti
              maxi_pagamenti_dlg = Views::Dialog::MaxiPagamentiDialog.new(self)
              maxi_pagamenti_dlg.center_on_screen(Wx::BOTH)
              answer = maxi_pagamenti_dlg.show_modal()
              if answer == Wx::ID_OK
                maxi_pagamento = calcola_residui_pendenti(ctrl.load_maxi_pagamento(maxi_pagamenti_dlg.selected))
                transfer_pagamento_fattura_to_view(build_pagamento_fattura_fornitore(maxi_pagamento))
                disable_widgets [lku_tipo_pagamento,
                                txt_data_pagamento, txt_note]
                txt_importo.activate()
              elsif answer == maxi_pagamenti_dlg.lku_tipo_pagamento.get_id
                evt.get_event_object().set_value(false)
                enable_widgets [lku_tipo_pagamento,
                                txt_data_pagamento, txt_note]
                evt_new = Views::Base::CustomEvent::NewEvent.new(:tipo_pagamento,
                  [
                    Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                    Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
                  ]
                )
                # This sends the event for processing by listeners
                process_event(evt_new)
              else
                evt.get_event_object().set_value(false)
                enable_widgets [lku_tipo_pagamento,
                                txt_data_pagamento, txt_note]
              end

              maxi_pagamenti_dlg.destroy()
            else
              ctrl.riapri_maxi_pagamento(evt.get_event_object().view_data)
              evt.get_event_object().view_data = nil
              enable_widgets [lku_tipo_pagamento,
                              txt_data_pagamento, txt_note]
              txt_importo.activate()
            end

          else
            evt.get_event_object().value = !evt.get_event_object().value
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def build_pagamento_fattura_fornitore(maxi_pagamento)
        Models::PagamentoFatturaFornitore.new(:maxi_pagamento_fornitore => maxi_pagamento,
                                            :importo => maxi_pagamento.residuo,
                                            :tipo_pagamento => maxi_pagamento.tipo_pagamento,
                                            :data_pagamento => maxi_pagamento.data_pagamento,
                                            :note => maxi_pagamento.note)
      end

      def reset_gestione_riga()
        reset_pagamento_fattura()
        lku_tipo_pagamento.set_default()
        enable_widgets [txt_importo, lku_tipo_pagamento,
                        txt_data_pagamento,
                        txt_note, tglbtn_maxi_pagamento_fornitore,
                        btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
        # imposto la data di oggi
        txt_data_pagamento.view_data = Date.today
      end

      def pagamento_compatibile?
        if self.pagamento_fattura.tipo_pagamento && self.pagamento_fattura.tipo_pagamento.conto_incompleto?
          Wx::message_box("La tipologia di pagamento utilizzata è incompleta.\nAggiungere l'informazione del conto nel pannello 'Scadenzario -> Impostazioni -> Incassi e Pagamenti.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          lku_tipo_pagamento.activate

          return false
        end

        return true
      end

      def update_riga_ui()
        if self.pagamento_fattura.registrato_in_prima_nota?
          disable_widgets [txt_importo, lku_tipo_pagamento,
                          txt_data_pagamento,
                          txt_note, tglbtn_maxi_pagamento_fornitore,
                          btn_aggiungi, btn_modifica]
          enable_widgets [btn_elimina, btn_nuovo]
        else
          if self.pagamento_fattura.maxi_pagamento_fornitore
            enable_widgets [txt_importo,
                            tglbtn_maxi_pagamento_fornitore]
            disable_widgets [lku_tipo_pagamento,
                            txt_data_pagamento,
                            txt_note]
          else
            enable_widgets [txt_importo, lku_tipo_pagamento,
                            txt_data_pagamento,
                            txt_note, tglbtn_maxi_pagamento_fornitore]
          end
          enable_widgets [btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
        end
      end


    end
  end
end
