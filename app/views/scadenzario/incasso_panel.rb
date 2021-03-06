# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/tipi_pagamento_dialog'

module Views
  module Scadenzario
    module IncassoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog dei conti

      def ui()

        model :tipo_pagamento_cliente => {:attrs => [:codice,
                                       :descrizione,
                                       :banca,
                                       :attivo,
                                       :predefinito,
                                       :cassa_dare,
                                       :cassa_avere,
                                       :banca_dare,
                                       :banca_avere,
                                       :fuori_partita_dare,
                                       :fuori_partita_avere,
                                       :nc_cassa_dare,
                                       :nc_cassa_avere,
                                       :nc_banca_dare,
                                       :nc_banca_avere,
                                       :nc_fuori_partita_dare,
                                       :nc_fuori_partita_avere],
                                     :alias => :incasso}

        controller :scadenzario

        logger.debug('initializing IncassoPanel...')
        xrc = Xrc.instance()
        # NotaSpese

        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_descrizione', self, :extends => TextField)
        xrc.find('lku_banca', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|banca| self.txt_descrizione_banca.view_data = (banca ? banca.descrizione : nil)},
                                :model => :banca,
                                :dialog => :banche_dialog,
                                :default => lambda {|banca| banca.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
        end

        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        subscribe(:evt_new_tipo_incasso) do
          reset_panel()
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)

        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('chk_predefinito', self, :extends => CheckField)

        xrc.find('chk_cassa_dare', self, :extends => CheckField)
        xrc.find('chk_cassa_avere', self, :extends => CheckField)
        xrc.find('chk_banca_dare', self, :extends => CheckField)
        xrc.find('chk_banca_avere', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_dare', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_avere', self, :extends => CheckField)

        xrc.find('chk_nc_cassa_dare', self, :extends => CheckField)
        xrc.find('chk_nc_cassa_avere', self, :extends => CheckField)
        xrc.find('chk_nc_banca_dare', self, :extends => CheckField)
        xrc.find('chk_nc_banca_avere', self, :extends => CheckField)
        xrc.find('chk_nc_fuori_partita_dare', self, :extends => CheckField)
        xrc.find('chk_nc_fuori_partita_avere', self, :extends => CheckField)

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

        reset_incasso_command_state()

        txt_codice.activate()

      end

      def reset_panel()
        begin
          reset_incasso()

          update_ui()

          reset_incasso_command_state()

          txt_codice.activate()

        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_codice_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if incasso = ctrl.load_tipo_pagamento_cliente_by_codice(txt_codice.view_data)
              self.incasso = incasso
              transfer_incasso_to_view()
              update_ui()
              reset_incasso_command_state()
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

      def btn_variazione_click(evt)
        begin
          transfer_incasso_from_view()
          tipi_pagamento_dlg = Views::Dialog::TipiPagamentoDialog.new(self, false)
          tipi_pagamento_dlg.center_on_screen(Wx::BOTH)
          if tipi_pagamento_dlg.show_modal() == Wx::ID_OK
            self.incasso = ctrl.load_tipo_pagamento_cliente(tipi_pagamento_dlg.selected)
            transfer_incasso_to_view()
            update_ui()
            reset_incasso_command_state()
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
                  transfer_incasso_from_view()
                  if self.incasso.valid?
                    ctrl.save_incasso()
                    evt_chg = Views::Base::CustomEvent::TipoPagamentoClienteChangedEvent.new(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::CLIENTI))
                    # This sends the event for processing by listeners
                    process_event(evt_chg)
                    Wx::message_box('Salvataggio avvenuto correttamente.',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                    process_event(Views::Base::CustomEvent::BackEvent.new())
                  else
                    Wx::message_box(self.incasso.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_incasso_error_field()

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
                res = Wx::message_box("Confermi l'eliminazione dell' incasso?",
                  'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  Wx::BusyCursor.busy() do
                    ctrl.delete_incasso()
                    evt_chg = Views::Base::CustomEvent::TipoPagamentoClienteChangedEvent.new(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::CLIENTI))
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

      def reset_incasso_command_state()
        if incasso.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione, lku_banca,
                          chk_cassa_dare, chk_cassa_avere,
                          chk_banca_dare, chk_banca_avere,
                          chk_fuori_partita_dare, chk_fuori_partita_avere,
                          chk_nc_cassa_dare, chk_nc_cassa_avere,
                          chk_nc_banca_dare, chk_nc_banca_avere,
                          chk_nc_fuori_partita_dare, chk_nc_fuori_partita_avere]
        else
          if incasso.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione, lku_banca,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere,
                            chk_nc_cassa_dare, chk_nc_cassa_avere,
                            chk_nc_banca_dare, chk_nc_banca_avere,
                            chk_nc_fuori_partita_dare, chk_nc_fuori_partita_avere]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione, lku_banca,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere,
                            chk_nc_cassa_dare, chk_nc_cassa_avere,
                            chk_nc_banca_dare, chk_nc_banca_avere,
                            chk_nc_fuori_partita_dare, chk_nc_fuori_partita_avere]

            if lku_banca.view_data
              lku_banca.enable(false)
            else
              if incasso.movimento_di_banca?
                lku_banca.enable(true)
              else
                lku_banca.enable(false)
              end
            end

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
        Helpers::AnagraficaHelper::CLIENTI
      end

    end
  end
end
