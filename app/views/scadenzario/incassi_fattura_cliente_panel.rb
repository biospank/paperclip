# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/maxi_incassi_dialog'
require 'app/views/scadenzario/incassi_fattura_cliente_common_actions'

module Views
  module Scadenzario
    module IncassiFatturaClientePanel
      include Views::Scadenzario::IncassiFatturaClienteCommonActions

      def ui

        model :pagamento_fattura_cliente => {:attrs => [:importo,
          :tipo_pagamento,
          :banca,
          :data_pagamento,
          :note,
          :maxi_pagamento_cliente],
          :alias => :incasso_fattura}

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
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
        end

        subscribe(:evt_tipo_pagamento_cliente_changed) do |data|
          lku_tipo_pagamento.load_data(data)
        end

        xrc.find('txt_descrizione_tipo_pagamento', self, :extends => TextField)

        xrc.find('lku_banca', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|banca| self.txt_descrizione_banca.view_data = (banca ? banca.descrizione : nil)},
                                :model => :banca,
                                :dialog => :banche_dialog,
                                :default => lambda {|banca| banca.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
        end

        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)
        xrc.find('txt_data_pagamento', self, :extends => DateField)
        xrc.find('txt_note', self, :extends => TextField)

        xrc.find('tglbtn_maxi_pagamento_cliente', self, :extends => ToggleLookupField)

        xrc.find('lstrep_incassi_fattura', self, :extends => EditableReportField) do |list|
          width = (configatron.screen.width <= 1024 ? 200 : 400)
          list.column_info([{:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Tipo', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Banca', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Data', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Note', :width => width, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'P', :width => 50, :align => Wx::LIST_FORMAT_CENTRE},
          ])
          list.data_info([{:attr => :importo, :format => :currency},
            {:attr => lambda {|incasso| (incasso.tipo_pagamento ? incasso.tipo_pagamento.descrizione : '')}},
            {:attr => lambda {|incasso| (incasso.banca ? incasso.banca.descrizione : '')}},
            {:attr => :data_pagamento, :format => :date},
            {:attr => :note},
            {:attr => lambda {|incasso| (incasso.registrato_in_prima_nota? ? '@' : '')}}
          ])
        end

        xrc.find('lbl_totale_incassi', self)
        xrc.find('lbl_residuo', self)

        xrc.find('lstrep_fonte_incassi_fattura', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Tipo', :width => 100, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Note', :width => 160, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Residuo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => :importo, :format => :currency},
            {:attr => lambda {|incasso| (incasso.tipo_pagamento ? incasso.tipo_pagamento.descrizione : '')}},
            {:attr => :note},
            {:attr => :data_pagamento, :format => :date},
            {:attr => lambda {|incasso| (incasso.residuo)}, :format => :currency}
          ])
        end

        xrc.find('lstrep_fatture_collegate', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Cliente', :width => 180},
            {:caption => 'Fattura', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Parziale', :width => 80, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => lambda {|incasso| incasso.fattura_cliente.cliente.denominazione}},
            {:attr => lambda {|incasso| incasso.fattura_cliente.num}},
            {:attr => lambda {|incasso| incasso.fattura_cliente.data_emissione}, :format => :date},
            {:attr => lambda {|incasso| incasso.fattura_cliente.importo}, :format => :currency},
            {:attr => lambda {|incasso| (incasso.importo)}, :format => :currency}
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
                              'lku_banca' => 'on_riga_text_enter',
                              'txt_note' => 'on_riga_text_enter'})

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F11, tglbtn_maxi_pagamento_cliente.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def lku_tipo_pagamento_after_change()
        begin
          tipo_pagamento = lku_tipo_pagamento.match_selection()
          collega_banca_al tipo_pagamento
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_tipo_pagamento_loose_focus()
        begin
          if tipo_pagamento = lku_tipo_pagamento.match_selection()
            if lku_banca.view_data.nil?
              collega_banca_al tipo_pagamento
            end
          else
            lku_banca.view_data = nil
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def on_riga_text_enter(evt)
        begin
          lku_tipo_pagamento.match_selection()
          lku_banca.match_selection()
          if(lstrep_incassi_fattura.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def tglbtn_maxi_pagamento_cliente_click(evt)
        begin
          if incasso_modificabile?
            # se il pulsante e' selezionato
            if evt.get_event_object().get_value() or
                incasso_fattura.new_record?
              # accedo alla gestione dei maxi incassi
              maxi_incassi_dlg = Views::Dialog::MaxiIncassiDialog.new(self)
              maxi_incassi_dlg.center_on_screen(Wx::BOTH)
              answer = maxi_incassi_dlg.show_modal()
              if answer == Wx::ID_OK
                maxi_incasso = calcola_residui_pendenti(ctrl.load_maxi_incasso(maxi_incassi_dlg.selected))
                transfer_incasso_fattura_to_view(build_incasso_fattura_cliente(maxi_incasso))
                disable_widgets [lku_tipo_pagamento, lku_banca,
                                txt_data_pagamento, txt_note]
                txt_importo.activate()
              elsif answer == maxi_incassi_dlg.lku_tipo_pagamento.get_id
                evt.get_event_object().set_value(false)
                enable_widgets [lku_tipo_pagamento, lku_banca,
                                txt_data_pagamento, txt_note]
                evt_new = Views::Base::CustomEvent::NewEvent.new(:tipo_incasso,
                  [
                    Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                    Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER
                  ]
                )
                # This sends the event for processing by listeners
                process_event(evt_new)
              elsif answer == maxi_incassi_dlg.lku_banca.get_id
                evt.get_event_object().set_value(false)
                enable_widgets [lku_tipo_pagamento, lku_banca,
                                txt_data_pagamento, txt_note]
                evt_new = Views::Base::CustomEvent::NewEvent.new(:banca,
                  [
                    Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                    Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER
                  ]
                )
                # This sends the event for processing by listeners
                process_event(evt_new)
              else
                evt.get_event_object().set_value(false)
                enable_widgets [lku_tipo_pagamento, lku_banca,
                                txt_data_pagamento, txt_note]
              end

              maxi_incassi_dlg.destroy()
            else
              ctrl.riapri_maxi_incasso(evt.get_event_object().view_data) if
              evt.get_event_object().view_data = nil
              enable_widgets [lku_tipo_pagamento, lku_banca,
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

      def build_incasso_fattura_cliente(maxi_incasso)
        Models::PagamentoFatturaCliente.new(:maxi_pagamento_cliente => maxi_incasso,
                                            :importo => maxi_incasso.residuo,
                                            :tipo_pagamento => maxi_incasso.tipo_pagamento,
                                            :banca => maxi_incasso.banca,
                                            :data_pagamento => maxi_incasso.data_pagamento,
                                            :note => maxi_incasso.note)
      end

      def reset_gestione_riga()
        reset_incasso_fattura()
        tipo_pagamento = lku_tipo_pagamento.set_default()
        collega_banca_al tipo_pagamento
        enable_widgets [txt_importo, lku_tipo_pagamento,
                        lku_banca, txt_data_pagamento,
                        txt_note, tglbtn_maxi_pagamento_cliente,
                        btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
        # imposto la data di oggi
        txt_data_pagamento.view_data = Date.today
#        tglbtn_maxi_pagamento_cliente.value = false
      end

      def incasso_compatibile?
        if self.incasso_fattura.tipo_pagamento && self.incasso_fattura.tipo_pagamento.conto_incompleto?
          Wx::message_box("La tipologia di incasso utilizzata ? incompleta.\nAggiungere le opzioni cassa, banca o fuori partita nel pannello 'Scadenzario -> Impostazioni -> Incassi e Pagamenti.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          lku_tipo_pagamento.activate

          return false
        end

        if(!self.incasso_fattura.compatibile?(owner.fattura_cliente.nota_di_credito?))
          Wx::message_box("La tipologia di incasso non e' compatibile con la banca.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          lku_tipo_pagamento.activate

          return false
        end

        # se all'incasso e' associato un tipo pagamento
        if(self.incasso_fattura.tipo_pagamento)
          # che presuppone un movimento di banca
          if(self.incasso_fattura.tipo_pagamento.movimento_di_banca?(owner.fattura_cliente.nota_di_credito?))
            # e l'incasso non ha una banca
            if(self.incasso_fattura.banca.nil?)
              # chiedo di inserire una banca
              Wx::message_box("La modalit? di incasso selezionata presuppone un movimento di banca:\nselezionare la banca se esiste, oppure, configurarne una nel pannello 'configurazione -> azienda'.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              lku_banca.activate

              return false
            end
          end
        end

        return true
      end

      def update_riga_ui()
        if self.incasso_fattura.registrato_in_prima_nota?
          disable_widgets [txt_importo, lku_tipo_pagamento,
                          lku_banca, txt_data_pagamento,
                          txt_note, tglbtn_maxi_pagamento_cliente,
                          btn_aggiungi, btn_modifica]
          enable_widgets [btn_elimina, btn_nuovo]
        else
          if self.incasso_fattura.maxi_pagamento_cliente
            enable_widgets [txt_importo,
                            tglbtn_maxi_pagamento_cliente]
#            tglbtn_maxi_pagamento_cliente.value = true
            disable_widgets [lku_tipo_pagamento,
                            lku_banca, txt_data_pagamento,
                            txt_note]
          else
            enable_widgets [txt_importo, lku_tipo_pagamento,
                            lku_banca, txt_data_pagamento,
                            txt_note, tglbtn_maxi_pagamento_cliente]
#            tglbtn_maxi_pagamento_cliente.value = false
          end
          enable_widgets [btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
        end
      end

    end
  end
end
