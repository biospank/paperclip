# encoding: utf-8

module Views
  module Fatturazione
    module RigheCorrispettiviCommonActions
      include Views::Base::Panel
      include Helpers::MVCHelper

      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog

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

      def lku_aliquota_after_change()
        begin
          transfer_riga_corrispettivo_from_view
          if lku_aliquota.match_selection()
            self.riga_corrispettivo.calcola_iva()
            self.riga_corrispettivo.calcola_imponibile()
            transfer_riga_corrispettivo_to_view
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def lku_aliquota_loose_focus()
        begin
          transfer_riga_corrispettivo_from_view
          if lku_aliquota.match_selection()
            self.riga_corrispettivo.calcola_iva()
            self.riga_corrispettivo.calcola_imponibile()
            transfer_riga_corrispettivo_to_view
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

    end
  end
end
