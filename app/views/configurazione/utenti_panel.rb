# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/utenti_dialog'

module Views
  module Configurazione
    module UtentiPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      attr_accessor :permessi

      def ui

        model :utente => {:attrs => [:login, :password]}
        controller :configurazione

        logger.debug('initializing UtentiPanel...')
        xrc = Xrc.instance()

        xrc.find('txt_login', self, :extends => TextField)
        xrc.find('txt_password', self, :extends => TextField)
        xrc.find('chklst_moduli', self, :extends => CheckListField)

        subscribe(:evt_moduli_azienda_changed) do |data|
          load_moduli(data)
        end

        xrc.find('chklst_permessi', self, :extends => CheckListField)

        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_nuovo', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
          load_moduli(ctrl.load_moduli_azienda())
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F3, btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuovo.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def init_panel()

      end

      def reset_panel()
        begin
          reset_utente()
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def btn_variazione_click(evt)
        begin
          transfer_utente_from_view()
          utenti_dlg = Views::Dialog::UtentiDialog.new(self)
          utenti_dlg.center_on_screen(Wx::BOTH)
          if utenti_dlg.show_modal() == Wx::ID_OK
            self.utente = ctrl.load_utente(utenti_dlg.selected)
            transfer_utente_to_view()
            load_moduli(ctrl.load_moduli_azienda())

            reset_utente_command_state()
            txt_password.activate()
          end

          utenti_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_salva_click(evt)
        begin
          Wx::BusyCursor.busy() do
            if btn_salva.enabled?
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
                  transfer_utente_from_view()
                  if self.utente.valid?
                    ctrl.save_utente()
                    Wx::message_box('Salvataggio avvenuto correttamente.',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                    load_moduli(ctrl.load_moduli_azienda())
                    reset_utente_command_state()
                    txt_login.activate()
                  else
                    Wx::message_box(self.utente.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_utente_error_field()

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
        rescue Exception => e
          log_error(self, e)
        end
        evt.skip()
      end

      def btn_nuovo_click(evt)
        begin
          reset_panel()
          load_moduli(ctrl.load_moduli_azienda())
          reset_utente_command_state()
          txt_login.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def chklst_moduli_check(evt)
        begin
#          logger.debug "evento check #{evt.inspect}"
#          logger.debug "item index #{evt.get_index}"
#          logger.debug "is checked #{evt.get_event_object().is_checked(evt.get_index)}"

          # foza la selezione dell'elemento ceccato
          evt.get_event_object().set_selection(evt.get_index)
          if evt.get_event_object().is_checked(evt.get_index)
            self.permessi[evt.get_index].lettura = true
            self.permessi[evt.get_index].scrittura = true
          else
            self.permessi[evt.get_index].lettura = false
            self.permessi[evt.get_index].scrittura = false
          end
          load_permesso(evt.get_index)
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def chklst_moduli_click(evt)
        begin
#          logger.debug "evento click #{evt.inspect}"
#          logger.debug "item index #{evt.get_index}"
#          logger.debug "is checked #{evt.get_event_object().is_checked(evt.get_index)}"
          load_permesso(evt.get_index)
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def chklst_permessi_check(evt)
        begin
#          logger.debug "evento check #{evt.inspect}"
#          logger.debug "item index #{evt.get_index}"
#          logger.debug "is checked #{evt.get_event_object().is_checked(evt.get_index)}"
#          logger.debug "chklst_moduli item selected #{chklst_moduli.get_selection()}"
          # foza la selezione dell'elemento ceccato
          evt.get_event_object().set_selection(evt.get_index)
          if evt.get_index == 0 # lettura
            self.permessi[chklst_moduli.get_selection()].lettura = evt.get_event_object().is_checked(evt.get_index)
            # se non può leggere
            unless evt.get_event_object().is_checked(evt.get_index)
              # non può neanche scrivere
              self.permessi[chklst_moduli.get_selection()].scrittura = false
            end
          end
          if evt.get_index == 1 # scrittura
            self.permessi[chklst_moduli.get_selection()].scrittura = evt.get_event_object().is_checked(evt.get_index)
            # se può scrivere può anche leggere
            self.permessi[chklst_moduli.get_selection()].lettura = true if evt.get_event_object().is_checked(evt.get_index)
          end
          load_permesso(chklst_moduli.get_selection())
          if evt.get_event_object().get_checked_items().empty?
            chklst_moduli.check(chklst_moduli.get_selection(), false)
          else
            chklst_moduli.check(chklst_moduli.get_selection(), true)
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def reset_utente_command_state()
        if utente.new_record?
          enable_widgets [txt_login]
          enable_widgets [chklst_moduli, chklst_permessi]
        else
          disable_widgets [txt_login]
          disable_widgets [chklst_moduli, chklst_permessi] if utente.admin?
        end
      end

      def load_moduli(moduli)
        self.permessi = {}
        chklst_permessi.clear()
        chklst_moduli.load_data(moduli,
                                :label => Proc.new {|ma| ma.modulo.nome})
        if utente.new_record?
          moduli.each_with_index do |ma, i|
            self.permessi[i] = Models::Permesso.new(:modulo_azienda => ma,
                                                    :lettura => false,
                                                    :scrittura => false)
          end
        else
          moduli.each_with_index do |ma, i|
            if permesso = utente.permessi_for(ma)
              self.permessi[i] = permesso
              chklst_moduli.check(i, (permesso.lettura? || permesso.scrittura?))
            else
              self.permessi[i] = Models::Permesso.new(:utente => utente,
                                                      :modulo_azienda => ma,
                                                      :lettura => false,
                                                      :scrittura => false)
            end
          end
        end
      end

      def load_permesso(indice_modulo)
        chklst_permessi.view_data = %w{Lettura Scrittura}
        chklst_permessi.update
        # permessi di lettura
        #logger.debug("permesso lettura: #{self.permessi[indice_modulo].lettura?}")
        chklst_permessi.check(0, self.permessi[indice_modulo].lettura?)
        # permessi di scrittura
        #logger.debug("permesso scrittura: #{self.permessi[indice_modulo].scrittura?}")
        chklst_permessi.check(1, self.permessi[indice_modulo].scrittura?)
        
      end
    end
  end
end