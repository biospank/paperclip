# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/prodotti_dialog'
require 'app/views/magazzino/righe_carico_panel'

module Views
  module Magazzino
    module CaricoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      def ui(container=nil)

        controller :magazzino

        logger.debug('initializing CaricoPanel...')
        xrc = Xrc.instance()

        xrc.find('chce_magazzino', self, :extends => ChoiceField)

        subscribe(:evt_dettaglio_magazzino_changed) do |data|
          logger.debug("callback evt_dettaglio_magazzino_changed!")
          chce_magazzino.load_data(data,
                  :label => :nome,
                  :if => lambda {|magazzino| magazzino.attivo? },
                  :select => :default,
                  :default => (data.detect { |magazzino| magazzino.predefinito? }) || data.first)

        end

        xrc.find('btn_salva', self)
        xrc.find('btn_pulisci', self)

        map_events(self)

        xrc.find('RIGHE_CARICO_PANEL', container,
          :extends => Views::Magazzino::RigheCaricoPanel,
          :force_parent => self)

        righe_carico_panel.ui()

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      def init_panel()
        righe_carico_panel.init_panel()
      end

      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          righe_carico_panel.reset_panel()

          righe_carico_panel.lku_bar_code.activate()

        rescue Exception => e
          log_error(self, e)
        end

      end

      # Gestione eventi

      def btn_salva_click(evt)
        begin
          # per controllare il tasto funzione F8 associato al salva
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
                  if righe_carico_panel.lstrep_righe_carico.get_item_count() > 0
                    ctrl.save_movimenti_carico()

                    anni_contabili_movimenti = ctrl.load_anni_contabili(Models::Movimento, 'data')
                    notify(:evt_anni_contabili_movimenti_changed, anni_contabili_movimenti)

                    Wx::message_box('Salvataggio avvenuto correttamente',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    reset_panel()
                  else
                    Wx::message_box("Leggere il codice a barre del prodotto oppure\npremere F5 per la ricerca manuale.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                  end
                  righe_carico_panel.lku_bar_code.activate()
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
