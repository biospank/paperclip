# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'
require 'app/views/dialog/prodotti_dialog'
require 'app/views/magazzino/righe_scarico_panel'

module Views
  module Magazzino
    module ClientePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui(container=nil)
        
        model :cliente => {:attrs => [:denominazione, :p_iva]}
        
        controller :magazzino

        logger.debug('initializing ClientePanel...')
        xrc = Xrc.instance()
        # Fattura cliente
        
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)

        xrc.find('btn_cliente', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_pulisci', self)

        map_events(self)

        xrc.find('RIGHE_SCARICO_PANEL', container,
          :extends => Views::Magazzino::RigheScaricoPanel,
          :force_parent => self)

        righe_scarico_panel.ui()

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      def init_panel()
        righe_scarico_panel.init_panel()
      end
      
      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_cliente()
          
          righe_scarico_panel.reset_panel()

          righe_scarico_panel.lku_bar_code.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def btn_cliente_click(evt)
        begin
          Wx::BusyCursor.busy() do
            clienti_dlg = Views::Dialog::ClientiDialog.new(self)
            clienti_dlg.center_on_screen(Wx::BOTH)
            answer = clienti_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_panel()
              self.cliente = ctrl.load_cliente(clienti_dlg.selected)
              transfer_cliente_to_view()
            elsif answer == clienti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:cliente, [Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW, Helpers::MagazzinoHelper::WXBRA_SCARICO_FOLDER])
              # This sends the event for processing by listeners
              process_event(evt_new)
            else
              logger.debug("You pressed Cancel")
            end

            clienti_dlg.destroy()
            righe_scarico_panel.lku_bar_code.activate()
          end
        rescue Exception => e
          log_error(self, e)
        end
        
        evt.skip()
      end

      def btn_salva_click(evt)
        begin
          # per controllare il tasto funzione F8 associato al salva
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
                if righe_scarico_panel.lstrep_righe_scarico.get_item_count() > 0
                  transfer_cliente_from_view()
                  ctrl.save_movimenti_scarico()

                  evt_chg = Views::Base::CustomEvent::MagazzinoChangedEvent.new()
                  # This sends the event for processing by listeners
                  process_event(evt_chg)

                  Wx::message_box('Salvataggio avvenuto correttamente',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

  #                res_stampa = Wx::message_box("Vuoi stampare la fattura?",
  #                  'Domanda',
  #                  Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)
  #
  #                if res_stampa == Wx::YES
  #                  btn_stampa_click(nil)
  #                end

                  reset_panel()
                else
                  Wx::message_box("Leggere il codice a barre del prodotto oppure\npremere F5 per la ricerca manuale.",
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
                righe_scarico_panel.lku_bar_code.activate()
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
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
      
      def btn_pulisci_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
    end
  end
end