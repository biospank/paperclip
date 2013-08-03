# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Magazzino
    module AliquotaProdottiPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui

        controller :configurazione

        logger.debug('initializing AliquotaProdottiPanel...')
        xrc = Xrc.instance()

        xrc.find('chce_aliquota_da', self, :extends => ChoiceField)

        subscribe(:evt_aliquota_changed) do |data|
          chce_aliquota_da.load_data(data,
                  :include_blank => {:label => ''},
                  :label => :descrizione,
                  :select => :first)
        end

        xrc.find('chce_aliquota_a', self, :extends => ChoiceField)

        subscribe(:evt_aliquota_changed) do |data|
          chce_aliquota_a.load_data(data,
                  :include_blank => {:label => ''},
                  :label => :descrizione,
                  :select => :first)
        end

        xrc.find('btn_salva', self)

        map_events(self)
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_panel()

      end

      def reset_panel()
        begin
          chce_aliquota_da.select_first()
          chce_aliquota_a.select_first()
          chce_aliquota_da.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
              if chce_aliquota_da.view_data.nil?
                Wx::message_box("Selezionare l'aliquota da sostituire",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)

                chce_aliquota_da.activate()

              elsif  chce_aliquota_a.view_data.nil?
                Wx::message_box("Selezionare l'aliquota da sostituire",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)

                chce_aliquota_a.activate()

              else
                # il progressivo puo' risultare a nil
                res = Wx::message_box("Confermi la sostituzione dell'aliquota per tutti i prodotti?",
                  'Domanda',
                  Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  Wx::BusyCursor.busy() do
                    ctrl.save_aliquota_prodotti(chce_aliquota_da.view_data, chce_aliquota_a.view_data)
                  end
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                  reset_panel()
                end
              end
            else
              Wx::message_box('Utente non autorizzato.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
            end
          end
        rescue Exception => e
          log_error(self, e)
        end
        evt.skip()
      end

    end
  end
end