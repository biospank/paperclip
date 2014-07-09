# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'
require 'app/views/dialog/pdc_dialog'

module Views
  module Anagrafica
    module ClientePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog

      def ui

        model :cliente => {:attrs => [:conto,
                                      :denominazione,
                                      :no_p_iva,
                                      :p_iva,
                                      :cod_fisc,
                                      :indirizzo,
                                      :comune,
                                      :provincia,
                                      :cap,
                                      :citta,
                                      :cellulare,
                                      :telefono,
                                      :fax,
                                      :e_mail,
                                      :pdc,
                                      :note,
                                      :attivo
          ]}
        controller :anagrafica

        logger.debug('initializing ClientePanel...')
        xrc = Xrc.instance()
        # Anagrafica cliente
        xrc.find('txt_conto', self, :extends => TextField)
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('chk_no_p_iva', self, :extends => CheckField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_cod_fisc', self, :extends => TextField)
        xrc.find('txt_indirizzo', self, :extends => TextField)
        xrc.find('txt_comune', self, :extends => TextField)
        xrc.find('txt_provincia', self, :extends => TextField)
        xrc.find('txt_cap', self, :extends => TextNumericField)
        xrc.find('txt_citta', self, :extends => TextField)
        xrc.find('txt_cellulare', self, :extends => TextField)
        xrc.find('txt_telefono', self, :extends => TextField)
        xrc.find('txt_fax', self, :extends => TextField)
        xrc.find('txt_e_mail', self, :extends => TextField)

        xrc.find('lku_pdc', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW,
                                :folder => Helpers::AnagraficaHelper::WXBRA_ANAGRAFICA_FOLDER)
        end

        xrc.find('txt_descrizione_pdc', self, :extends => TextField)
        xrc.find('txt_note', self, :extends => TextField)
        xrc.find('chk_attivo', self, :extends => CheckField)
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc.load_data(data)
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([lku_pdc]) : disable_widgets([lku_pdc])
        end

        subscribe(:evt_new_cliente) do
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
        reset_cliente_command_state()
      end
      # Gestione eventi
      
      def chk_no_p_iva_click(evt)
        update_ui()
      end
      
      def btn_variazione_click(evt)
        logger.debug("Cliccato sul bottone variazione!")
        begin
          clienti_dlg = Views::Dialog::ClientiDialog.new(self, false)
          clienti_dlg.center_on_screen(Wx::BOTH)
          answer = clienti_dlg.show_modal()
          if answer == Wx::ID_OK
            self.cliente = ctrl.load_cliente(clienti_dlg.selected)
            transfer_cliente_to_view()
            update_ui()
            reset_cliente_command_state()
            txt_denominazione.activate()
          else
            logger.debug("You pressed Cancel")
          end

          clienti_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end
        logger.debug("Cliente: #{self.cliente.inspect}")
      end

      def btn_salva_click(evt)
        logger.debug("Cliccato sul bottone salva!")
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::ANAGRAFICA
                  transfer_cliente_from_view()
                  if pdc_compatibile?
                    if self.cliente.valid?
                      ctrl.save_cliente()
                      evt_chg = Views::Base::CustomEvent::ClienteChangedEvent.new(ctrl.search_clienti())
                      # This sends the event for processing by listeners
                      process_event(evt_chg)
                      Wx::message_box('Salvataggio avvenuto correttamente.',
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)
                      reset_panel()
                      process_event(Views::Base::CustomEvent::BackEvent.new())
                    else
                      Wx::message_box(self.cliente.error_msg,
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      focus_cliente_error_field()

                    end
                  end
                else
                  Wx::message_box('Utente non autorizzato.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
              else
                Wx::message_box("Licenza scaduta il #{ctrl.licenza.data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
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
        logger.debug("Cliente: #{self.cliente.inspect}")
        evt.skip()
      end

      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if ctrl.licenza.attiva?
              if can? :write, Helpers::ApplicationHelper::Modulo::ANAGRAFICA
                if self.cliente.modificabile?
                  res = Wx::message_box("Confermi l'eliminazione del cliente?",
                    'Domanda',
                    Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                  if res == Wx::YES
                    Wx::BusyCursor.busy() do
                      ctrl.delete_cliente()
                      evt_chg = Views::Base::CustomEvent::ClienteChangedEvent.new(ctrl.search_clienti())
                      # This sends the event for processing by listeners
                      process_event(evt_chg)
                      reset_panel()
                    end
                  end
                else
                  Wx::message_box("Il cliente non puo' essere eliminato.",
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            else
              Wx::message_box("Licenza scaduta il #{ctrl.licenza.data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
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

      # sovrascritto per agganciare il filtro sul criterio di ricerca
      def lku_pdc_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            self.dialog_sql_criteria = self.pdc_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW,
                  Helpers::AnagraficaHelper::WXBRA_ANAGRAFICA_FOLDER
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

      def btn_nuovo_click(evt)
        logger.debug("Cliccato sul bottone nuovo!")
        reset_panel()
      end

      def reset_panel()
        reset_cliente()
        reset_cliente_command_state()
        txt_p_iva.enable(true)
        chk_attivo.value = true
        txt_denominazione.activate()
      end
			
      def update_ui()
        if chk_no_p_iva.checked?
          txt_p_iva.clear()
          txt_p_iva.enable(false)
        else
          txt_p_iva.enable(true)
        end
      end
      
      def reset_cliente_command_state()
        if cliente.new_record?
          disable_widgets [btn_elimina]
        else
          if self.cliente.modificabile?
            enable_widgets [btn_elimina]
          else
            disable_widgets [btn_elimina]
          end
        end

        if configatron.bilancio.attivo
          if self.cliente.new_record?
            lku_pdc.enable(true)
          else
            if lku_pdc.view_data
              if self.cliente.modificabile?
                lku_pdc.enable(true)
              else
                lku_pdc.enable(false)
              end
            else
              lku_pdc.enable(true)
            end
          end
        end
      end

      def pdc_compatibile?
        if configatron.bilancio.attivo
          if self.cliente.pdc && self.cliente.pdc.costo?
            res = Wx::message_box("Il conto associato non è un ricavo.\nVuoi forzare il dato?",
              'Avvertenza',
              Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

              if res == Wx::NO
                lku_pdc.activate()
                return false
              end

          end
        end

        return true
      end

      def pdc_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::RICAVO}')"
      end

    end
  end
end