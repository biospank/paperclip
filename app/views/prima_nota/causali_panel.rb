# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/causali_dialog'
require 'app/views/prima_nota/causali_common_actions'

module Views
  module PrimaNota
    module CausaliPanel
      include Views::PrimaNota::CausaliCommonActions

      def ui()

        model :causale => {:attrs => [:codice,
                                       :descrizione,
                                       :banca,
                                       :attiva,
                                       :predefinita,
                                       :descrizione_agg,
                                       :cassa_dare,
                                       :cassa_avere,
                                       :banca_dare,
                                       :banca_avere,
                                       :fuori_partita_dare,
                                       :fuori_partita_avere]}

        controller :prima_nota

        logger.debug('initializing CausaliPanel...')
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
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)

        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        subscribe(:evt_new_causale) do
          reset_panel()
        end

        xrc.find('chk_attiva', self, :extends => CheckField)
        xrc.find('chk_predefinita', self, :extends => CheckField)
        xrc.find('txt_descrizione_agg', self, :extends => TextField)

        xrc.find('chk_cassa_dare', self, :extends => CheckField)
        xrc.find('chk_cassa_avere', self, :extends => CheckField)
        xrc.find('chk_banca_dare', self, :extends => CheckField)
        xrc.find('chk_banca_avere', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_dare', self, :extends => CheckField)
        xrc.find('chk_fuori_partita_avere', self, :extends => CheckField)

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
                          lku_banca, txt_descrizione_agg,
                          chk_cassa_dare, chk_cassa_avere,
                          chk_banca_dare, chk_banca_avere,
                          chk_fuori_partita_dare, chk_fuori_partita_avere]
        else
          if causale.modificabile?
            enable_widgets [btn_elimina, txt_codice, txt_descrizione,
                            lku_banca, txt_descrizione_agg,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere]
          else
            disable_widgets [btn_elimina, txt_codice, txt_descrizione,
                            txt_descrizione_agg,
                            chk_cassa_dare, chk_cassa_avere,
                            chk_banca_dare, chk_banca_avere,
                            chk_fuori_partita_dare, chk_fuori_partita_avere]

            if lku_banca.view_data
              lku_banca.enable(false)
            else
              if causale.movimento_di_banca?
                lku_banca.enable(true)
              else
                lku_banca.enable(false)
              end
            end

          end
        end
      end

    end
  end
end
