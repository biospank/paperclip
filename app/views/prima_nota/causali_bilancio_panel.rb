# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/causali_dialog'
require 'app/views/prima_nota/causali_common_actions'

module Views
  module PrimaNota
    module CausaliBilancioPanel
      include Views::PrimaNota::CausaliCommonActions

      def ui()

        model :causale => {:attrs => [:codice,
                                       :descrizione,
                                       :attiva,
                                       :predefinita,
                                       :descrizione_agg,
                                       :pdc_dare,
                                       :pdc_avere]}

        controller :prima_nota

        logger.debug('initializing CausaliBilancioPanel...')
        xrc = Xrc.instance()
        # NotaSpese

        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_descrizione', self, :extends => TextField)

        xrc.find('lku_pdc_dare', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_dare', self, :extends => TextField)

        xrc.find('lku_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc_dare.load_data(data)
          lku_pdc_avere.load_data(data)
        end

        subscribe(:evt_new_causale) do
          reset_panel()
        end

        xrc.find('chk_attiva', self, :extends => CheckField)
        xrc.find('chk_predefinita', self, :extends => CheckField)
        xrc.find('txt_descrizione_agg', self, :extends => TextField)

        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuova', self)

        disable_widgets [btn_elimina]

        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F3, btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuova.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def reset_causale_command_state()
        if causale.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [txt_codice, txt_descrizione,
                          txt_descrizione_agg]
        else
          if causale.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione,
                            txt_descrizione_agg]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione,
                            txt_descrizione_agg]
          end
        end

        if configatron.bilancio.attivo
          if self.causale.new_record?
            lku_pdc_dare.enable(true)
            lku_pdc_avere.enable(true)
          else
            if lku_pdc_dare.view_data
              if self.causale.modificabile?
                lku_pdc_dare.enable(true)
              else
                lku_pdc_dare.enable(false)
              end
            else
              lku_pdc_dare.enable(true)
            end
            if lku_pdc_avere.view_data
              if self.causale.modificabile?
                lku_pdc_avere.enable(true)
              else
                lku_pdc_avere.enable(false)
              end
            else
              lku_pdc_avere.enable(true)
            end
          end
        end
      end


    end
  end
end
