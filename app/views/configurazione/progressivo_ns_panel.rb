# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Configurazione
    module ProgressivoNotaSpesePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui

        model :progressivo_nota_spese => {:attrs => [:anno_rif, :progressivo],
                                               :alias => :progressivo
        }
        controller :configurazione

        logger.debug('initializing ProgressivoNotaSpesePanel...')
        xrc = Xrc.instance()

# il wxstaticboxsizer non e' visibile nel file .xrc
#        xrc.find('cpt_nota_spese', self) do |cpt|
#          cpt.label = Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]
#        end

        xrc.find('chce_anno_rif', self, :extends => ChoiceStringField)

        subscribe(:evt_progressivo_ns) do |data|
          chce_anno_rif.load_data(data,
                  :include_blank => {:label => ''},
                  :select => :first)
        end

        xrc.find('txt_progressivo', self, :extends => NumericField)

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
          reset_progressivo()

          chce_anno_rif.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def chce_anno_rif_select(evt)
        begin
          anno = evt.get_event_object().view_data()
          if self.progressivo = ctrl.search_progressivo(Models::ProgressivoNotaSpese, anno)
            transfer_progressivo_to_view()
          else
            txt_progressivo.view_data = ''
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
              # il progressivo puo' risultare a nil
              if self.progressivo
                transfer_progressivo_from_view()
                if self.progressivo.valid?
                  res = Wx::message_box("Confermi la modifica del progressivo #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i].downcase}?",
                    'Domanda',
                    Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                  if res == Wx::YES
                    ctrl.save_progressivo()
                    Wx::message_box('Salvataggio avvenuto correttamente.',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    reset_panel()
                  end
                else
                  Wx::message_box(self.progressivo.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_progressivo_error_field()

                end
              else
                Wx::message_box("Selezionare l'anno del progressivo da modificare.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
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