# encoding: utf-8

module Views
  module Scadenzario
    module PagamentiFatturaFornitoreCommonActions
      include Views::Base::Panel
      include Helpers::MVCHelper

      def init_panel()
        begin
          reset_gestione_riga()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def reset_panel()
        begin
          reset_gestione_riga()

          lstrep_pagamenti_fattura.reset()
          self.result_set_lstrep_pagamenti_fattura = []

          reset_liste_collegate()

          riepilogo_fattura()

        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_importo_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              owner.txt_importo.activate()
            else
              lku_tipo_pagamento.activate()
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      # sovrascritto per chiamare il metodo load_tipo_pagamento_fornitore
      def lku_tipo_pagamento_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            dlg = Views::Dialog::TipiPagamentoDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_tipo_pagamento.view_data = ctrl.load_tipo_pagamento_fornitore(dlg.selected)
              lku_tipo_pagamento_after_change()
            elsif answer == dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:tipo_pagamento,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
                ]
              )
              # This sends the event for processing by listeners
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
          transfer_pagamento_fattura_from_view()
          if fornitore? and pagamento_compatibile?
            if self.pagamento_fattura.valid?
              self.result_set_lstrep_pagamenti_fattura << self.pagamento_fattura
              lstrep_pagamenti_fattura.display(self.result_set_lstrep_pagamenti_fattura)
              lstrep_pagamenti_fattura.force_visible(:last)
              riepilogo_fattura()
              reset_gestione_riga()
              reset_liste_collegate()
              txt_importo.activate()
            else
              Wx::message_box(self.pagamento_fattura.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_pagamento_fattura_error_field()

            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_modifica_click(evt)
        begin
          transfer_pagamento_fattura_from_view()
          if fornitore? and pagamento_modificabile? and pagamento_compatibile?
            if self.pagamento_fattura.valid?
              self.pagamento_fattura.log_attr()
              lstrep_pagamenti_fattura.display(self.result_set_lstrep_pagamenti_fattura)
              riepilogo_fattura()
              reset_gestione_riga()
              reset_liste_collegate()
              txt_importo.activate()
            else
              Wx::message_box(self.pagamento_fattura.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_pagamento_fattura_error_field()

            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_elimina_click(evt)
        begin
          salva = true
          if fornitore?
            if pagamento_fattura.congelato?
              res = Wx::message_box("Scrittura gi� stampata in definitivo.\nConfermi la cancellazione?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                salva = false
              end
            end
            if salva
              self.pagamento_fattura.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
              lstrep_pagamenti_fattura.display(self.result_set_lstrep_pagamenti_fattura)
              riepilogo_fattura()
              reset_gestione_riga()
              reset_liste_collegate()
              txt_importo.activate()
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_nuovo_click(evt)
        begin
          if fornitore?
            reset_gestione_riga()
            # serve ad eliminare l'eventuale focus dalla lista
            # evita che rimanga selezionato un elemento della lista
            lstrep_pagamenti_fattura.display(self.result_set_lstrep_pagamenti_fattura)
            reset_liste_collegate()
            txt_importo.activate()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def lstrep_pagamenti_fattura_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_pagamenti_fattura.each do |record|
            if record.ident() == row_id
              self.pagamento_fattura = record
              break
            end
          end
          transfer_pagamento_fattura_to_view()
          reset_liste_collegate()
          display_fonte_pagamento_fattura()
          update_riga_ui()
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_pagamenti_fattura_item_activated(evt)
        txt_importo.activate()
      end

      def display_pagamenti_fattura_fornitore(fattura, pagamento = nil)
        self.result_set_lstrep_pagamenti_fattura = ctrl.search_pagamenti_fattura_fornitore(fattura)
        lstrep_pagamenti_fattura.display(self.result_set_lstrep_pagamenti_fattura)
        reset_gestione_riga()
        if pagamento
          self.result_set_lstrep_pagamenti_fattura.each_with_index do |record, index|
            if record.id == pagamento.id
              self.pagamento_fattura = record
              lstrep_pagamenti_fattura.set_item_state(index, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED)
#              set_focus()
              break
            end
          end
          transfer_pagamento_fattura_to_view()
          reset_liste_collegate()
          display_fonte_pagamento_fattura()
          update_riga_ui()
        end
      end

      def display_fonte_pagamento_fattura()
        if maxi_pagamento = self.pagamento_fattura.maxi_pagamento_fornitore
          maxi_pagamento.calcola_residuo()
          self.result_set_lstrep_fonte_pagamenti_fattura = [maxi_pagamento]
          lstrep_fonte_pagamenti_fattura.display(self.result_set_lstrep_fonte_pagamenti_fattura, :ignore_focus => true)
          display_fatture_collegate(self.result_set_lstrep_fonte_pagamenti_fattura.first())
        end
      end

      def display_fatture_collegate(maxi_pagamento)
        self.result_set_lstrep_fatture_collegate = maxi_pagamento.pagamenti_fattura_fornitore.reject { |pagamento| pagamento.fattura_fornitore.id == owner.fattura_fornitore.id  }
        lstrep_fatture_collegate.display(self.result_set_lstrep_fatture_collegate, :ignore_focus => true)
      end

      def fornitore?
        return owner.fornitore?
      end

      def pagamento_modificabile?
        if self.pagamento_fattura.registrato_in_prima_nota?
          Wx::message_box('Pagamento non modificabile.',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          return false
        else
          return true
        end
      end

      def riepilogo_fattura()
        totale_pagamenti = 0.0
        importo_fattura = owner.fattura_fornitore.importo || 0.0

        self.result_set_lstrep_pagamenti_fattura.each do |pagamento|
          if pagamento.valid_record?
            totale_pagamenti += pagamento.importo
          end
        end

        owner.fattura_fornitore.totale_pagamenti = totale_pagamenti

        self.lbl_residuo.foreground_colour = self.lbl_totale_pagamenti.foreground_colour = ((Helpers::ApplicationHelper.real(totale_pagamenti) == Helpers::ApplicationHelper.real(importo_fattura)) ? Wx::BLACK : Wx::RED)
        self.lbl_totale_pagamenti.label = Helpers::ApplicationHelper.currency(totale_pagamenti)
        self.lbl_residuo.label = Helpers::ApplicationHelper.currency(importo_fattura - totale_pagamenti)

      end

      def categoria()
        Helpers::AnagraficaHelper::FORNITORI
      end

      def calcola_residui_pendenti(maxi_pagamento)
        self.result_set_lstrep_pagamenti_fattura.each do |pagamento_fattura|
          # se l'pagamento fattura e' stato cancellato o modificato
          if (pagamento_fattura.instance_status == Helpers::BusinessClassHelper::ST_DELETE) ||
              (pagamento_fattura.instance_status == Helpers::BusinessClassHelper::ST_UPDATE)
            # ma prima di essere cancellato/modificato e' stato cambiato
            if pagamento_fattura.maxi_pagamento_fornitore_id_changed?
              # controllo se il maxi pagamento era dello stesso tipo
              if pagamento_fattura.maxi_pagamento_fornitore_id_was == maxi_pagamento.id
                maxi_pagamento.residuo += (pagamento_fattura.importo_changed? ? pagamento_fattura.importo_was : pagamento_fattura.importo)
              end
            else
              # se invece non e' stato cambiato prima di essere cancellato/modificato
              if pagamento_fattura.maxi_pagamento_fornitore_id == maxi_pagamento.id
                # controllo se il maxi pagamento era dello stesso tipo
                maxi_pagamento.residuo += (pagamento_fattura.importo_changed? ? pagamento_fattura.importo_was : pagamento_fattura.importo)
              end
            end
          elsif (pagamento_fattura.instance_status == Helpers::BusinessClassHelper::ST_INSERT)
            if pagamento_fattura.maxi_pagamento_fornitore_id == maxi_pagamento.id
              maxi_pagamento.residuo -= pagamento_fattura.importo
            end
          end
        end
        maxi_pagamento
      end

      def reset_liste_collegate()
        lstrep_fonte_pagamenti_fattura.reset()
        self.result_set_lstrep_fonte_pagamenti_fattura = []
        lstrep_fatture_collegate.reset()
        self.result_set_lstrep_fatture_collegate = []
      end

      def collega_banca_al(tipo_pagamento)
        if(tipo_pagamento)
          # se alla modalita di pagamento e' associata una banca
          if(tipo_pagamento.banca)
            # visualizzo quella associata
            lku_banca.match_selection(tipo_pagamento.banca.codice)
          else
            # se la modalita di pagamento movimenta la banca
            if tipo_pagamento.movimento_di_banca?
              # se esiste una banca predefinita
              if lku_banca.default
                # visualizzo quella predefinita
                lku_banca.set_default()
              else
                # nel caso ci siano piu' banche attive,
                banche_attive = lku_banca.select_all {|banca| banca.attiva?}
                # gli associo l'unica banca attiva disponibile
                if banche_attive.length == 1
                  lku_banca.view_data = banche_attive.first
                # altrimenti viene chiesto all'utente
                else
                  lku_banca.view_data = nil
                end
              end
            else
              # la banca non viene impostata
              lku_banca.view_data = nil
            end
          end
        else
          # senza modalita di pagamento non viene impostata la banca
          lku_banca.view_data = nil
        end
      end

    end
  end
end
