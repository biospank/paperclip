# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/fatturazione/corrispettivi_common_actions'
require 'app/views/fatturazione/righe_corrispettivi_bilancio_panel'

module Views
  module Fatturazione
    module CorrispettiviBilancioPanel
      include Views::Fatturazione::CorrispettiviCommonActions

      def ui(container=nil)

        model :filtro => {:attrs => []}

        controller :fatturazione

        logger.debug('initializing CorrispettiviBilancioPanel...')
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

        xrc.find('RIGHE_CORRISPETTIVI_BILANCIO_PANEL', container,
          :extends => Views::Fatturazione::RigheCorrispettiviBilancioPanel,
          :force_parent => self,
          :alias => :righe_corrispettivi_panel)

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

        subscribe(:evt_dettaglio_corrispettivo) do |corrispettivo|
          reset_panel()
          chce_anno.view_data = corrispettivo.data.year
          chce_mese.view_data = ("%02d" % corrispettivo.data.month)
          logger.debug("mese corrispettivo #{corrispettivo.data.month}")
          transfer_filtro_from_view()
          corrispettivi = ctrl.search_corrispettivi()
          righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
          righe_corrispettivi_panel.riepilogo_corrispettivi()
          righe_corrispettivi_panel.init_panel()
        end

      end

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
                res = Wx::message_box("Il conto in dare non � un conto patrimoniale attivo.\nVuoi forzare il dato?",
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
                res = Wx::message_box("Il conto in avere non � un ricavo.\nVuoi forzare il dato?",
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

      def dare_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}')"
      end

      def avere_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::RICAVO}')"
      end

    end
  end
end
