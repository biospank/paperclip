# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/fatturazione/righe_corrispettivi_panel'

module Views
  module Fatturazione
    module CorrispettiviPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      #include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog

      def ui(container=nil)

        model :filtro => {:attrs => []}
        
        controller :fatturazione

        logger.debug('initializing CorrispettiviPanel...')
        xrc = Xrc.instance()
        # Corrispettivi
        
        xrc.find('chce_anno', self, :extends => ChoiceStringField) do |chce|
          # carico gli anni contabili
          chce.load_data(ctrl.load_anni_contabili(Models::Corrispettivo, 'data'),
            :select => :last)
        end

        subscribe(:evt_anni_contabili_corrispettivi_changed) do |data|
          chce_anno.load_data(data,
            :select => :last)
        end

        xrc.find('chce_mese', self, :extends => ChoiceField) do |chce|
          chce.load_data(Helpers::ApplicationHelper::MESI,
            :label => :descrizione,
            :select => (Date.today.month - 1))
        end

        xrc.find('lku_aliquota', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|aliquota| self.txt_descrizione_aliquota.view_data = (aliquota ? aliquota.descrizione : nil)},
                                :model => :aliquota,
                                :dialog => :aliquote_dialog,
                                :default => lambda {|aliquota| aliquota.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
        end

        xrc.find('txt_descrizione_aliquota', self, :extends => TextField)

# chce_aliquota (esempio di implementazione con gestione del default)
#        xrc.find('chce_aliquota', self, :extends => ChoiceField)
#
#        subscribe(:evt_aliquota_changed) do |data|
#          chce_aliquota.load_data(data,
#                  :label => :descrizione,
#                  :if => lambda {|aliquota| aliquota.attiva?},
#                  :select => :default,
#                  :default => (data.detect { |aliquota| aliquota.predefinita? }) || data.first)
#        end

        xrc.find('lku_pdc_dare', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_dare', self, :extends => TextField)

        if pdc_dare = configatron.corrispettivi.retrieve(:default_pdc_dare)
          lku_pdc_dare.view_data = ctrl.load_pdc(pdc_dare) rescue nil
        end

        xrc.find('lku_pdc_avere', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)

        if pdc_avere = configatron.corrispettivi.retrieve(:default_pdc_avere)
          lku_pdc_avere.view_data = ctrl.load_pdc(pdc_avere) rescue nil
        end

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc_dare.load_data(data)
          lku_pdc_avere.load_data(data)
        end

        subscribe(:evt_aliquota_changed) do |data|
          lku_aliquota.load_data(data)
          lku_aliquota.set_default()
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([lku_pdc_dare, lku_pdc_avere]) : disable_widgets([lku_pdc_dare, lku_pdc_avere])
        end

        xrc.find('btn_salva', self)

        map_events(self)

        xrc.find('RIGHE_CORRISPETTIVI_PANEL', container,
          :extends => Views::Fatturazione::RigheCorrispettiviPanel,
          :force_parent => self)

        righe_corrispettivi_panel.ui()
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_load_corrispettivi) do
          transfer_filtro_from_view()
          corrispettivi = ctrl.search_corrispettivi()
          righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
          righe_corrispettivi_panel.riepilogo_corrispettivi()
          righe_corrispettivi_panel.init_panel()
        end
      end

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
      
      def lku_pdc_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.dare_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              pdc_selezionato = ctrl.load_pdc(dlg.selected)
              if pdc_selezionato.conto_economico? || pdc_selezionato.ricavo?
                res = Wx::message_box("Il conto in dare non è un conto patrimoniale attivo.\nVuoi forzare il dato?",
                  'Avvertenza',
                  Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

                  if res == Wx::NO
                    return
                  end

              end
              lku_pdc_dare.view_data = pdc_selezionato
              lku_pdc_dare_after_change()
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

     def lku_pdc_dare_after_change()
        begin
          pdc_dare = lku_pdc_dare.match_selection()
          configatron.corrispettivi.default_pdc_dare = (pdc_dare ? pdc_dare.id : nil)
          righe_corrispettivi_panel.init_gestione_riga()
          righe_corrispettivi_panel.txt_giorno.activate()
          process_event(Views::Base::CustomEvent::ConfigChangedEvent.new(nil))
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_pdc_dare_loose_focus()
        begin
          pdc_dare = lku_pdc_dare.match_selection()
          configatron.corrispettivi.default_pdc_dare = (pdc_dare ? pdc_dare.id : nil)
          righe_corrispettivi_panel.init_gestione_riga()
          process_event(Views::Base::CustomEvent::ConfigChangedEvent.new(nil))
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
              pdc_selezionato = ctrl.load_pdc(dlg.selected)
              if pdc_selezionato.costo?
                res = Wx::message_box("Il conto in avere non è un ricavo.\nVuoi forzare il dato?",
                  'Avvertenza',
                  Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

                  if res == Wx::NO
                    return
                  end

              end
              lku_pdc_avere.view_data = pdc_selezionato
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

      def lku_pdc_avere_after_change()
        begin
          pdc_avere = lku_pdc_avere.match_selection()
          configatron.corrispettivi.default_pdc_avere = (pdc_avere ? pdc_avere.id : nil)
          righe_corrispettivi_panel.init_gestione_riga()
          righe_corrispettivi_panel.txt_giorno.activate()
          process_event(Views::Base::CustomEvent::ConfigChangedEvent.new(nil))
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_pdc_avere_loose_focus()
        begin
          pdc_avere = lku_pdc_avere.match_selection()
          configatron.corrispettivi.default_pdc_avere = (pdc_avere ? pdc_avere.id : nil)
          righe_corrispettivi_panel.init_gestione_riga()
          process_event(Views::Base::CustomEvent::ConfigChangedEvent.new(nil))
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_salva_click(evt)
        begin
          # per controllare il tasto funzione F8 associato al salva
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                ctrl.save_corrispettivi()
                Wx::message_box('Salvataggio avvenuto correttamente',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
                
                notify(:evt_load_corrispettivi)

                scritture = search_scritture()
                notify(:evt_prima_nota_changed, scritture)

              else
                Wx::message_box('Utente non autorizzato.',
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

      def dare_sql_criteria()
        "pdc.type in ('#{Models::Pdc::ATTIVO}')"
      end

      def avere_sql_criteria()
        "pdc.type in ('#{Models::Pdc::RICAVO}')"
      end

    end
  end
end