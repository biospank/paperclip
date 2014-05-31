# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Magazzino
    module RigheScaricoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      attr_accessor :aliquote_iva, :riepilogo_importi, :totale_prodotti,
                    :totale_imponibile, :totale_iva, :totale_fattura

      def ui
        self.aliquote_iva = {}
        self.riepilogo_importi = {}

        model :scarico => {:attrs => [:qta, :data, :imponibile, :prezzo_vendita]},
              :prodotto => {:attrs => []}

        controller :magazzino

        xrc = Xrc.instance()

        xrc.find('lku_bar_code', self, :extends => LookupTextField) do |f|
          #evt_text(f) { |evt| lku_bar_code_change(evt) }
          f.tool_tip = 'Usare il lettore oppure premere F5 per la ricerca manuale'
        end

        xrc.find('txt_qta', self, :extends => NumericField)
        xrc.find('txt_data', self, :extends => DateField)
        xrc.find('txt_codice_prodotto', self, :extends => TextField)
        xrc.find('txt_descrizione_prodotto', self, :extends => TextField)
        xrc.find('txt_residuo', self, :extends => TextField)
        xrc.find('txt_imponibile', self, :extends => DecimalField)
        xrc.find('txt_descrizione_aliquota', self, :extends => TextField)
        xrc.find('txt_prezzo_vendita', self, :extends => DecimalField)

        width = (configatron.screen.width <= 1024 ? 300 : 400)

        xrc.find('lstrep_righe_scarico', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Codice', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Descrizione', :width => width, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Qta', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Imponibile', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Iva', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Totale', :width => 120, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => lambda {|riga| riga.prodotto.codice}},
            {:attr => lambda {|riga| riga.prodotto.descrizione}},
            {:attr => :qta},
            {:attr => :data, :format => :date},
            {:attr => lambda {|riga| (riga.imponibile * riga.qta)}, :format => :currency},
            {:attr => lambda {|riga| (riga.prodotto.aliquota ? (((riga.imponibile * riga.qta) * riga.prodotto.aliquota.percentuale) / 100) : nil)}, :format => :currency},
            {:attr => lambda do |riga|
                if riga.prodotto.aliquota
                  (riga.imponibile * riga.qta) + (((riga.imponibile * riga.qta) * riga.prodotto.aliquota.percentuale) / 100)
                else
                  nil
                end
              end, :format => :currency
            }
          ])
        end

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        xrc.find('lstrep_iva', self, :extends => ReportField) do |lstrep|

          lstrep.column_info([{:caption => 'Aliquota', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Imponibile', :width => 150, :align => Wx::LIST_FORMAT_RIGHT},
              {:caption => 'Iva', :width => 150, :align => Wx::LIST_FORMAT_RIGHT}
            ])
          lstrep.data_info([{:attr => :aliquota, :format => :percentage},
              {:attr => :imponibile, :format => :currency},
              {:attr => :iva, :format => :currency}])

        end

        xrc.find('lbl_prodotti', self)
        xrc.find('lbl_imponibile', self)
        xrc.find('lbl_iva', self)
        xrc.find('lbl_totale', self)

        map_events(self)

        map_text_enter(self, {'txt_qta' => 'on_riga_text_enter', 'txt_data' => 'on_riga_text_enter', 'txt_prezzo_vendita' => 'on_riga_text_enter'})

        subscribe(:evt_aliquota_changed) do |aliquote|
          self.aliquote_iva.clear
          aliquote.each do |aliquota|
            self.aliquote_iva[aliquota.id] = aliquota
          end
        end
      end

      def init_panel()
        begin
          reset_gestione_riga()
          lku_bar_code.activate()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def reset_panel()
        begin
          reset_gestione_riga()

          lstrep_righe_scarico.reset()
          self.result_set_lstrep_righe_scarico = []
          lstrep_iva.reset()
          self.result_set_lstrep_iva = []

          riepilogo_scarico()
          lku_bar_code.activate()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def on_riga_text_enter(evt)
        begin
          if(lstrep_righe_scarico.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      # Gestione eventi
      # chiamato prima che il testo cambia
      def lku_bar_code_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            prodotti_dialog()
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def prodotti_dialog()
        begin
          if magazzino?
            Wx::BusyCursor.busy() do
              prodotti_dlg = Views::Dialog::ProdottiDialog.new(self)
              prodotti_dlg.center_on_screen(Wx::BOTH)
              answer = prodotti_dlg.show_modal()
              if answer == Wx::ID_OK
                self.prodotto = ctrl.load_prodotto(prodotti_dlg.selected)
                prodotto.calcola_residuo(:magazzino => owner.chce_magazzino.view_data)
                self.scarico = Models::Scarico.new(
                  :prodotto => prodotto,
                  :magazzino_id => owner.chce_magazzino.view_data,
                  :imponibile => prodotto.imponibile,
                  :prezzo_vendita => prodotto.prezzo_vendita,
                  :qta => 1,
                  :data => Date.today()
                )

                transfer_scarico_to_view()
                display_dati_prodotto()
                txt_qta.activate()

              elsif answer == prodotti_dlg.btn_nuovo.get_id
                evt_new = Views::Base::CustomEvent::NewEvent.new(:prodotto, :righe_scarico_panel)
                # This sends the event for processing by listeners
                process_event(evt_new)
              end

              prodotti_dlg.destroy()

            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      # chiamato da evt_text_enter in wx_helper
      # il lettore di codici a barre emette una stringa di caratteri
      # seguita dal carattere invio che scatena questo evento
      def lku_bar_code_enter(evt)
        begin
          if (barcode = lku_bar_code.view_data()).empty?
            Wx::message_box("Inserire il codice oppure premere F5 per la ricerca manuale.",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            lku_bar_code.activate()
          else
            Wx::BusyCursor.busy() do
              if self.prodotto = ctrl.load_scarico_prodotto_by_bar_code(owner.chce_magazzino.view_data, barcode)
                prodotto.calcola_residuo(:magazzino => owner.chce_magazzino.view_data)
                self.scarico = Models::Scarico.new(
                  :prodotto => prodotto,
                  :magazzino_id => owner.chce_magazzino.view_data,
                  :imponibile => prodotto.imponibile,
                  :prezzo_vendita => prodotto.prezzo_vendita,
                  :qta => 1,
                  :data => Date.today()
                )
                self.result_set_lstrep_righe_scarico << self.scarico
                lstrep_righe_scarico.display(self.result_set_lstrep_righe_scarico)
                lstrep_righe_scarico.force_visible(:last)
                lstrep_righe_scarico.force_selected(:last) # forza l'evento lstrep_righe_scarico_item_selected
                riepilogo_scarico()
                lku_bar_code.activate()
              else
                Wx::message_box("Il codice letto non corrisponde a nessun prodotto.\nPremere F5 per la ricerca manuale.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
                reset_gestione_riga()
                lku_bar_code.activate()
              end
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_aggiungi_click(evt)
        begin
          if magazzino?
            if prodotto
              if qta_non_valida?
                Wx::message_box("Quantità deve essere maggiore di 0",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)

                txt_qta.activate()

              elsif data_non_valida?
                Wx::message_box("Data non valida o formalmente errata",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)

                txt_data.activate()

              else
                transfer_scarico_from_view()
                self.scarico.calcola_imponibile()
                self.result_set_lstrep_righe_scarico << self.scarico
                lstrep_righe_scarico.display(self.result_set_lstrep_righe_scarico)
                lstrep_righe_scarico.force_visible(:last)
                riepilogo_scarico()
                reset_gestione_riga()
                lku_bar_code.activate()
              end
            else
              Wx::message_box("Leggere il codice a barre del prodotto oppure\npremere F5 per la ricerca manuale.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              lku_bar_code.activate()
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_modifica_click(evt)
        begin
          if qta_non_valida?
            Wx::message_box("Quantità deve essere maggiore di 0",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)

            txt_qta.activate()

          elsif data_non_valida?
            Wx::message_box("Data non valida o formalmente errata",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)

            txt_data.activate()

          else
            transfer_scarico_from_view()
            self.scarico.calcola_imponibile()
            self.scarico.log_attr()
            lstrep_righe_scarico.display(self.result_set_lstrep_righe_scarico)
            riepilogo_scarico()
            reset_gestione_riga()
            lku_bar_code.activate()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def qta_non_valida?()
        txt_qta.view_data.to_i <= 0
      end

      def data_non_valida?()
        txt_data.view_data.nil?
      end

      def btn_elimina_click(evt)
        begin
          self.scarico.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
          lstrep_righe_scarico.display(self.result_set_lstrep_righe_scarico)
          riepilogo_scarico()
          reset_gestione_riga()
          lku_bar_code.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_nuovo_click(evt)
        begin
          reset_gestione_riga()
          # serve ad eliminare l'eventuale focus dalla lista
          # evita che rimanga selezionato un elemento della lista
          lstrep_righe_scarico.display(self.result_set_lstrep_righe_scarico)
          lku_bar_code.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def lstrep_righe_scarico_item_selected(evt)
        begin
          logger.debug("lstrep_righe_scarico_item_selected")
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_scarico.each do |record|
            if record.ident() == row_id
              self.scarico = record
              self.prodotto = self.scarico.prodotto
              break
            end
          end
          transfer_scarico_to_view()
          display_dati_prodotto()
          update_riga_ui()
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_righe_scarico_item_activated(evt)
        lku_bar_code.activate()
      end

      def reset_gestione_riga()
        reset_scarico()
        self.prodotto = nil
        display_dati_prodotto()
        enable_widgets [lku_bar_code, txt_qta, txt_data,
                        btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end

      def update_riga_ui()
        if(lstrep_righe_scarico.get_selected_item_count() > 0)
          enable_widgets [btn_modifica, btn_elimina]
          disable_widgets [btn_aggiungi]
        else
          disable_widgets [btn_modifica, btn_elimina]
          enable_widgets [btn_aggiungi]
        end
      end

      def display_dati_prodotto()
        if prodotto
          lku_bar_code.view_data = prodotto.bar_code
          txt_codice_prodotto.view_data = prodotto.codice
          txt_descrizione_prodotto.view_data = prodotto.descrizione
          txt_residuo.view_data = calcola_residuo(prodotto)
          txt_descrizione_aliquota.view_data = (prodotto.aliquota ? prodotto.aliquota.descrizione : nil)
#          if prodotto.aliquota
#            txt_prezzo_vendita.view_data = scarico.imponibile + ((scarico.imponibile * prodotto.aliquota.percentuale) / 100)
#          else
#            txt_prezzo_vendita.view_data = nil
#          end
        else
          lku_bar_code.view_data = nil
          txt_codice_prodotto.view_data = nil
          txt_descrizione_prodotto.view_data = nil
          txt_residuo.view_data = nil
          txt_descrizione_aliquota.view_data = nil
#          txt_prezzo_vendita.view_data = nil
        end
      end

      def calcola_residuo(prodotto)
        residuo = prodotto.residuo
        self.result_set_lstrep_righe_scarico.each do |riga|
          if riga.valid_record?
            if riga.prodotto_id == prodotto.id
              residuo -= riga.qta
            end
          end
        end
        residuo
      end

      def riepilogo_scarico()
        self.totale_prodotti = 0
        self.totale_imponibile = 0.0
        self.totale_iva = 0.0
        self.totale_fattura = 0.0

        self.riepilogo_importi = {}

        self.result_set_lstrep_righe_scarico.each do |riga|
          if riga.valid_record?
            importo = (riepilogo_importi[riga.prodotto.aliquota_id] || 0.0)
            riepilogo_importi[riga.prodotto.aliquota_id] = importo + (riga.imponibile * riga.qta)
            self.totale_prodotti += riga.qta
#            riepilogo_importi[riga.prodotto.aliquota_id] = (importo + ((riga.qta.zero?) ? riga.prezzo_vendita : (riga.prezzo_vendita * riga.qta)))
          end
        end

        data_matrix = []

        riepilogo_importi.each_pair do |aliquota_id, imponibile_iva|
          data = []
          data << aliquote_iva[aliquota_id].percentuale
          data << imponibile_iva
          data << ((imponibile_iva * aliquote_iva[aliquota_id].percentuale) / 100)

          data_matrix << data

          self.totale_imponibile += imponibile_iva
          self.totale_iva += ((imponibile_iva * aliquote_iva[aliquota_id].percentuale) / 100)

        end

        self.totale_fattura = self.totale_imponibile + self.totale_iva

        lstrep_iva.display_matrix(data_matrix)

        lbl_prodotti.label = self.totale_prodotti.to_s
        lbl_imponibile.label = Helpers::ApplicationHelper.currency(self.totale_imponibile)
        lbl_iva.label = Helpers::ApplicationHelper.currency(self.totale_iva)
        lbl_totale.label = Helpers::ApplicationHelper.currency(self.totale_fattura)

      end

      def magazzino?
        unless magazzino_ref
            Wx::message_box("Selezionare un magazzino di riferimento.",
              'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          owner.chce_magazzino.set_focus()

          return false

        end

        return true

      end

      def magazzino_ref
        owner.chce_magazzino.view_data
      end

    end
  end
end
