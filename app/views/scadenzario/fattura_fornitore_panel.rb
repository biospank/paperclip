# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/fornitori_dialog'
require 'app/views/dialog/righe_fattura_pdc_fornitori_dialog'
require 'app/views/dialog/fatture_fornitori_dialog'
require 'app/views/dialog/tipi_pagamento_dialog'
require 'app/views/dialog/banche_dialog'
require 'app/views/scadenzario/fattura_fornitore_common_actions'
require 'app/views/scadenzario/pagamenti_fattura_fornitore_panel'

module Views
  module Scadenzario
    module FatturaFornitorePanel
      include Views::Scadenzario::FatturaFornitoreCommonActions

      def ui(container=nil)

        model :fornitore => {:attrs => [:denominazione, :p_iva]},
          :fattura_fornitore => {:attrs => [:num,
                                            :data_emissione,
                                            :data_registrazione,
                                            :importo,
                                            :nota_di_credito]}

        controller :scadenzario

        logger.debug('initializing FatturaFornitorePanel...')
        xrc = Xrc.instance()
        # Fattura fornitore

        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_num', self, :extends => TextField) do |field|
          field.evt_char { |evt| txt_num_keypress(evt) }
        end
        xrc.find('txt_data_emissione', self, :extends => DateField) do |field|
          field.move_after_in_tab_order(txt_num)
        end
        xrc.find('txt_data_registrazione', self, :extends => DateField) do |field|
          field.move_after_in_tab_order(txt_data_emissione)
        end
        xrc.find('txt_importo', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_importo_keypress(evt) }
        end
        xrc.find('btn_pdc', self)
        xrc.find('chk_nota_di_credito', self, :extends => CheckField)

        xrc.find('btn_fornitore', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_indietro', self)

        map_events(self)

        map_text_enter(self, {'txt_importo' => 'on_importo_enter'})

        xrc.find('PAGAMENTI_FATTURA_FORNITORE_PANEL', container,
          :extends => Views::Scadenzario::PagamentiFatturaFornitorePanel,
          :force_parent => self)

        pagamenti_fattura_fornitore_panel.ui()

        subscribe(:evt_dettaglio_pagamento) do |pagamento|
          self.fattura_fornitore = pagamento.fattura_fornitore
          self.fornitore = self.fattura_fornitore.fornitore
          self.righe_fattura_pdc = ctrl.search_righe_fattura_pdc_fornitori(self.fattura_fornitore)
          transfer_fornitore_to_view()
          transfer_fattura_fornitore_to_view()
          pagamenti_fattura_fornitore_panel.display_pagamenti_fattura_fornitore(self.fattura_fornitore, pagamento)
          pagamenti_fattura_fornitore_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          disable_widgets [txt_data_registrazione] if configatron.bilancio.attivo

          reset_fattura_fornitore_command_state()
          pagamenti_fattura_fornitore_panel.txt_importo.activate()

        end

        subscribe(:evt_dettaglio_fattura_fornitore_scadenzario) do |fattura|
          reset_panel()
          self.fattura_fornitore = fattura
          self.fornitore = self.fattura_fornitore.fornitore
          self.righe_fattura_pdc = ctrl.search_righe_fattura_pdc_fornitori(self.fattura_fornitore)
          transfer_fornitore_to_view()
          transfer_fattura_fornitore_to_view()
          pagamenti_fattura_fornitore_panel.display_pagamenti_fattura_fornitore(self.fattura_fornitore)
          pagamenti_fattura_fornitore_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          disable_widgets [txt_data_registrazione]

          reset_fattura_fornitore_command_state()
          pagamenti_fattura_fornitore_panel.txt_importo.activate()

        end

        subscribe(:evt_liquidazioni_attivo) do |data|
          if configatron.liquidazioni.attivo
            enable_widgets([btn_pdc])
          else
            disable_widgets([btn_pdc])
          end
        end

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

    end
  end
end
