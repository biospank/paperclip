# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Magazzino
    module RigheCaricoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      def ui
        model :carico => {:attrs => [:qta, :data, :prezzo_acquisto, :prezzo_vendita, :note]},
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
        xrc.find('txt_prezzo_acquisto', self, :extends => DecimalField)
        xrc.find('txt_prezzo_vendita', self, :extends => DecimalField)
        xrc.find('txt_note', self, :extends => TextField)

        width = (configatron.screen.width <= 1024 ? 200 : 300)

        xrc.find('lstrep_righe_carico', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Codice', :width => 130, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Descrizione', :width => width, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Qta', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Prezzo Acq.', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Prezzo Ven.', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Note', :width => width, :align => Wx::LIST_FORMAT_LEFT}
          ])
          list.data_info([{:attr => lambda {|riga| riga.prodotto.codice}},
            {:attr => lambda {|riga| riga.prodotto.descrizione}},
            {:attr => :qta},
            {:attr => :data, :format => :date},
            {:attr => :prezzo_acquisto, :format => :currency},
            {:attr => :prezzo_vendita, :format => :currency},
            {:attr => :note}
          ])
        end

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        map_events(self)

        map_text_enter(self, {'txt_qta' => 'on_riga_text_enter',
                              'txt_data' => 'on_riga_text_enter',
                              'txt_prezzo_acquisto' => 'on_riga_text_enter',
                              'txt_prezzo_vendita' => 'on_riga_text_enter',
                              'txt_note' => 'on_riga_text_enter'})

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

          lstrep_righe_carico.reset()
          self.result_set_lstrep_righe_carico = []

          lku_bar_code.activate()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def on_riga_text_enter(evt)
        begin
          if(lstrep_righe_carico.get_selected_item_count() > 0)
            logger.debug("modifica")
            btn_modifica_click(evt)
          else
            logger.debug("aggiungi")
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
          Wx::BusyCursor.busy() do
            prodotti_dlg = Views::Dialog::ProdottiDialog.new(self)
            prodotti_dlg.center_on_screen(Wx::BOTH)
            answer = prodotti_dlg.show_modal()
            if answer == Wx::ID_OK
              self.prodotto = ctrl.load_prodotto(prodotti_dlg.selected)
              prodotto.calcola_residuo(:magazzino => owner.chce_magazzino.view_data)
              self.carico = Models::Carico.new(
                :prodotto => prodotto,
                :magazzino_id => owner.chce_magazzino.view_data,
                :prezzo_acquisto => prodotto.prezzo_acquisto,
                :prezzo_vendita => prodotto.prezzo_vendita,
                :qta => 1,
                :data => Date.today()
              )

              transfer_carico_to_view()
              display_dati_prodotto()
              txt_qta.activate()

            elsif answer == prodotti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:prodotto, :righe_carico_panel)
              # This sends the event for processing by listeners
              process_event(evt_new)
            end

            prodotti_dlg.destroy()
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
              if self.prodotto = ctrl.load_prodotto_by_bar_code(barcode)
                prodotto.calcola_residuo(:magazzino => owner.chce_magazzino.view_data)
                self.carico = Models::Carico.new(
                  :prodotto => prodotto,
                  :magazzino_id => owner.chce_magazzino.view_data,
                  :prezzo_acquisto => prodotto.prezzo_acquisto,
                  :prezzo_vendita => prodotto.prezzo_vendita,
                  :qta => 1,
                  :data => Date.today()
                )
                self.result_set_lstrep_righe_carico << self.carico
                lstrep_righe_carico.display(self.result_set_lstrep_righe_carico)
                lstrep_righe_carico.force_visible(:last)
                lstrep_righe_carico.force_selected(:last) # forza l'evento lstrep_righe_carico_item_selected
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
                transfer_carico_from_view()
                self.carico.calcola_imponibile()
                if((self.carico.prezzo_acquisto != prodotto.prezzo_acquisto) ||
                      (self.carico.prezzo_vendita != prodotto.prezzo_vendita))
                  prodotto.update_attributes(
                    :prezzo_acquisto => self.carico.prezzo_acquisto,
                    :imponibile => self.carico.imponibile,
                    :prezzo_vendita => self.carico.prezzo_vendita
                  )
                end
                self.result_set_lstrep_righe_carico << self.carico
                lstrep_righe_carico.display(self.result_set_lstrep_righe_carico)
                lstrep_righe_carico.force_visible(:last)
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
            transfer_carico_from_view()
            self.carico.calcola_imponibile()
            if((self.carico.prezzo_acquisto != prodotto.prezzo_acquisto) ||
                  (self.carico.prezzo_vendita != prodotto.prezzo_vendita))
              prodotto.update_attributes(
                :prezzo_acquisto => self.carico.prezzo_acquisto,
                :imponibile => self.carico.imponibile,
                :prezzo_vendita => self.carico.prezzo_vendita
              )
            end
            self.carico.log_attr()
            lstrep_righe_carico.display(self.result_set_lstrep_righe_carico)
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
          self.carico.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
          lstrep_righe_carico.display(self.result_set_lstrep_righe_carico)
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
          lstrep_righe_carico.display(self.result_set_lstrep_righe_carico)
          lku_bar_code.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def lstrep_righe_carico_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_carico.each do |record|
            if record.ident() == row_id
              self.carico = record
              self.prodotto = self.carico.prodotto
              break
            end
          end
          transfer_carico_to_view()
          display_dati_prodotto()
          update_riga_ui()
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_righe_carico_item_activated(evt)
        lku_bar_code.activate()
      end

      def reset_gestione_riga()
        reset_carico()
        self.prodotto = nil
        display_dati_prodotto()
        enable_widgets [lku_bar_code, txt_qta, txt_data,
                        btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end

      def update_riga_ui()
        if(lstrep_righe_carico.get_selected_item_count() > 0)
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
        else
          lku_bar_code.view_data = nil
          txt_codice_prodotto.view_data = nil
          txt_descrizione_prodotto.view_data = nil
          txt_residuo.view_data = nil
        end
      end

      def calcola_residuo(prodotto)
        residuo = prodotto.residuo
        self.result_set_lstrep_righe_carico.each do |riga|
          if riga.valid_record?
            if riga.prodotto_id == prodotto.id
              residuo += riga.qta
            end
          end
        end
        residuo
      end

      def magazzino?
        unless owner.chce_magazzino.view_data
            Wx::message_box("Selezionare un magazzino di riferimento.",
              'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          owner.chce_magazzino.set_focus()

          return false

        end

        return true

      end

    end
  end
end
