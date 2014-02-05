# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/norma_dialog'

module Views
  module PrimaNota
    module InteressiPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui()

        model :interessi_liquidazione_trimestrale => {:attrs => [:percentuale], :alias => :interesse}

        controller :prima_nota

        logger.debug('initializing InteressiPanel...')
        xrc = Xrc.instance()
        # NotaSpese

        xrc.find('txt_percentuale', self, :extends => DecimalField)

        xrc.find('btn_salva', self)

        map_events(self)

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def init_panel()
        self.interesse = load_interessi_liquidazione_trimestrale()
        transfer_interesse_to_view()
      end

      def reset_panel()

      end

      # Gestione eventi
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
                transfer_interesse_from_view()
                if self.interesse.valid?
                  ctrl.save_interessi_liquidazione_trimestrale()
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                else
                  Wx::message_box(self.norma.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_interesse_error_field()

                end
              else
                Wx::message_box('Utente non autorizzato.',
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

    end
  end
end