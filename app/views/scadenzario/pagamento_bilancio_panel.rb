# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/tipi_pagamento_dialog'

module Views
  module Scadenzario
    module PagamentoBilancioPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog dei conti

      def ui()

        model :tipo_pagamento_fornitore => {:attrs => [:codice,
                                       :descrizione,
                                       :attivo,
                                       :predefinito,
                                        :pdc_dare,
                                        :pdc_avere,
                                        :nc_pdc_dare,
                                        :nc_pdc_avere],
                                     :alias => :pagamento}

        controller :scadenzario

        logger.debug('initializing PagamentoBilancioPanel...')
        xrc = Xrc.instance()
        # NotaSpese

        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_descrizione', self, :extends => TextField)

        subscribe(:evt_new_tipo_pagamento) do
          reset_panel()
        end

        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('chk_predefinito', self, :extends => CheckField)

        xrc.find('lku_pdc_dare', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_dare', self, :extends => TextField)

        xrc.find('lku_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)

        xrc.find('lku_nc_pdc_dare', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_nc_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        xrc.find('txt_descrizione_nc_pdc_dare', self, :extends => TextField)

        xrc.find('lku_nc_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_nc_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        xrc.find('txt_descrizione_nc_pdc_avere', self, :extends => TextField)

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc_dare.load_data(data)
          lku_pdc_avere.load_data(data)
          lku_nc_pdc_dare.load_data(data)
          lku_nc_pdc_avere.load_data(data)
        end

        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        disable_widgets [btn_elimina]

        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F3, btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuovo.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def init_panel()

        reset_pagamento_command_state()

        txt_codice.activate()

      end

      def reset_panel()
        begin
          reset_pagamento()

          update_ui()

          reset_pagamento_command_state()

          txt_codice.activate()

        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_codice_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if pagamento = ctrl.load_tipo_pagamento_fornitore_by_codice(txt_codice.view_data)
              self.pagamento = pagamento
              transfer_pagamento_to_view()
              update_ui()
              reset_pagamento_command_state()
            end
            evt.skip()
          when Wx::K_F5
            btn_variazione_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def chk_attivo_click(evt)
        update_ui()
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
              lku_pdc_dare.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_dare_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER
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

      def lku_pdc_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.avere_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc_avere.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_avere_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER
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

      def lku_nc_pdc_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.dare_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_nc_pdc_dare.view_data = ctrl.load_pdc(dlg.selected)
              lku_nc_pdc_dare_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER
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

      def lku_nc_pdc_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.avere_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_nc_pdc_avere.view_data = ctrl.load_pdc(dlg.selected)
              lku_nc_pdc_avere_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER
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

      def btn_variazione_click(evt)
        begin
          transfer_pagamento_from_view()
          tipi_pagamento_dlg = Views::Dialog::TipiPagamentoDialog.new(self, false)
          tipi_pagamento_dlg.center_on_screen(Wx::BOTH)
          if tipi_pagamento_dlg.show_modal() == Wx::ID_OK
            self.pagamento = ctrl.load_tipo_pagamento_fornitore(tipi_pagamento_dlg.selected)
            transfer_pagamento_to_view()
            update_ui()
            reset_pagamento_command_state()
            txt_codice.activate() if txt_codice.enabled?

          else
            logger.debug("You pressed Cancel")
          end

          tipi_pagamento_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::SCADENZARIO
                  transfer_pagamento_from_view()
                  if self.pagamento.valid?
                    if pagamento_compatibile?
                      ctrl.save_pagamento()
                      evt_chg = Views::Base::CustomEvent::TipoPagamentoFornitoreChangedEvent.new(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::FORNITORI))
                      # This sends the event for processing by listeners
                      process_event(evt_chg)
                      Wx::message_box('Salvataggio avvenuto correttamente.',
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)
                      reset_panel()
                      process_event(Views::Base::CustomEvent::BackEvent.new())
                    end
                  else
                    Wx::message_box(self.pagamento.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_pagamento_error_field()

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
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if ctrl.licenza.attiva?
              if can? :write, Helpers::ApplicationHelper::Modulo::SCADENZARIO
                res = Wx::message_box("Confermi l'eliminazione dell' pagamento?",
                  'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  Wx::BusyCursor.busy() do
                    ctrl.delete_pagamento()
                    evt_chg = Views::Base::CustomEvent::TipoPagamentoFornitoreChangedEvent.new(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::FORNITORI))
                    # This sends the event for processing by listeners
                    process_event(evt_chg)
                    reset_panel()
                  end
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
            txt_codice.activate()
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_nuovo_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def reset_pagamento_command_state()
        if pagamento.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione,
            lku_pdc_dare, lku_pdc_avere, lku_nc_pdc_dare, lku_nc_pdc_avere]
        else
          if pagamento.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione,
              lku_pdc_dare, lku_pdc_avere, lku_nc_pdc_dare, lku_nc_pdc_avere]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione,
              lku_pdc_dare, lku_pdc_avere, lku_nc_pdc_dare, lku_nc_pdc_avere]
          end
        end
      end

      def update_ui()
        if chk_attivo.checked?
          enable_widgets [chk_predefinito]
        else
          chk_predefinito.view_data = false
          disable_widgets [chk_predefinito]
        end
      end

      def categoria()
        Helpers::AnagraficaHelper::FORNITORI
      end

      def dare_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::COSTO}')"
      end

      def avere_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::RICAVO}')"
      end

      def pagamento_compatibile?

        if self.pagamento.pdc_dare && self.pagamento.pdc_dare.ricavo?
          res = Wx::message_box("Il conto fattura in dare non è un costo.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_pdc_dare.activate()
              return false
            end
        end

        if self.pagamento.nc_pdc_dare && self.pagamento.nc_pdc_dare.ricavo?
          res = Wx::message_box("Il conto nota di credito in dare non è un costo.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_nc_pdc_dare.activate()
              return false
            end
        end

        if self.pagamento.pdc_avere && self.pagamento.pdc_avere.costo?
          res = Wx::message_box("Il conto fattura in avere non è un ricavo.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_pdc_avere.activate()
              return false
            end
        end

        if self.pagamento.nc_pdc_avere && self.pagamento.nc_pdc_avere.costo?
          res = Wx::message_box("Il conto nota di credito in avere non è un ricavo.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_nc_pdc_avere.activate()
              return false
            end
        end

        if(((self.pagamento.pdc_dare && self.pagamento.pdc_dare.costo?) &&
              (self.pagamento.pdc_avere && self.pagamento.pdc_avere.ricavo?)) ||
            ((self.pagamento.pdc_dare && self.pagamento.pdc_dare.ricavo?) &&
              (self.pagamento.pdc_avere && self.pagamento.pdc_avere.costo?)))

          res = Wx::message_box("Presenza nei conti fattura di due conti economici.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_pdc_dare.activate()
              return false
            end
        end

        if(((self.pagamento.nc_pdc_dare && self.pagamento.nc_pdc_dare.costo?) &&
              (self.pagamento.nc_pdc_avere && self.pagamento.nc_pdc_avere.ricavo?)) ||
            ((self.pagamento.nc_pdc_dare && self.pagamento.nc_pdc_dare.ricavo?) &&
              (self.pagamento.nc_pdc_avere && self.pagamento.nc_pdc_avere.costo?)))

          res = Wx::message_box("Presenza nei conti di nota di credito di due conti economici.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_nc_pdc_dare.activate()
              return false
            end
        end

        return true
      end

    end
  end
end
