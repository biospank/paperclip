# encoding: utf-8

module Views
  module Fatturazione
    module CorrispettiviCommonActions
      include Views::Base::Panel
      include Helpers::MVCHelper
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog

      # viene chiamato al cambio folder
      def init_panel()
        righe_corrispettivi_panel.init_panel()
        righe_corrispettivi_panel.txt_giorno.activate()
      end

      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          righe_corrispettivi_panel.reset_panel()
          righe_corrispettivi_panel.txt_giorno.activate()
        rescue Exception => e
          log_error(self, e)
        end

      end

      # Gestione eventi

      def chce_anno_select(evt)
        begin
          Wx::BusyCursor.busy() do
            salva_modifiche_pendenti()
            transfer_filtro_from_view()
            corrispettivi = ctrl.search_corrispettivi()
            righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
            righe_corrispettivi_panel.riepilogo_corrispettivi()
            righe_corrispettivi_panel.init_gestione_riga()
            righe_corrispettivi_panel.txt_giorno.activate()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def chce_mese_select(evt)
        begin
          Wx::BusyCursor.busy() do
            salva_modifiche_pendenti()
            transfer_filtro_from_view()
            corrispettivi = ctrl.search_corrispettivi()
            righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
            righe_corrispettivi_panel.riepilogo_corrispettivi()
            righe_corrispettivi_panel.init_gestione_riga()
            righe_corrispettivi_panel.txt_giorno.activate()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def lku_aliquota_after_change()
        begin
          Wx::BusyCursor.busy() do
            lku_aliquota.match_selection()
            salva_modifiche_pendenti()
            transfer_filtro_from_view()
            corrispettivi = ctrl.search_corrispettivi()
            righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
            righe_corrispettivi_panel.riepilogo_corrispettivi()
            righe_corrispettivi_panel.init_gestione_riga()
            righe_corrispettivi_panel.txt_giorno.activate()
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      def lku_aliquota_loose_focus()
        begin
          Wx::BusyCursor.busy() do
            lku_aliquota.match_selection()
            salva_modifiche_pendenti()
            transfer_filtro_from_view()
            corrispettivi = ctrl.search_corrispettivi()
            righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
            righe_corrispettivi_panel.riepilogo_corrispettivi()
            righe_corrispettivi_panel.init_gestione_riga()
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

# chce_aliquota (sempio di evento select)
#      def chce_aliquota_select(evt)
#        begin
#          Wx::BusyCursor.busy() do
#            salva_modifiche_pendenti()
#            transfer_filtro_from_view()
#            corrispettivi = ctrl.search_corrispettivi()
#            righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
#            righe_corrispettivi_panel.riepilogo_corrispettivi()
#            righe_corrispettivi_panel.init_gestione_riga()
#            righe_corrispettivi_panel.txt_giorno.activate()
#          end
#        rescue Exception => e
#          log_error(self, e)
#        end
#
#        evt.skip()
#      end

      def btn_salva_click(evt)
        begin
          # per controllare il tasto funzione F8 associato al salva
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                  ctrl.save_corrispettivi()
                  Wx::message_box('Salvataggio avvenuto correttamente',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  notify(:evt_load_corrispettivi)

                  scritture = search_scritture()
                  notify(:evt_prima_nota_changed, scritture)

                  if configatron.bilancio.attivo
                    scritture = search_scritture_pd()
                    # TODO gestire la notifica evt_partita_doppia_changed
                    notify(:evt_partita_doppia_changed, scritture)
                  end

                else
                  Wx::message_box('Utente non autorizzato.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
              else
                Wx::message_box("Licenza scaduta il #{ctrl.licenza.get_data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
            righe_corrispettivi_panel.txt_giorno.activate()
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("Il documento e' stato modificato da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def salva_modifiche_pendenti
        if righe_corrispettivi_panel.changed?
          res = Wx::message_box("I dati dei corrispettivi sono stati modificati.\nSalvare le modifiche?",
            'Avvertenza',
            Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

          if res == Wx::YES
            ctrl.save_corrispettivi()
          end

        end

      end

    end
  end
end
