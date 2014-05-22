# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'
require 'app/views/dialog/righe_fattura_pdc_clienti_dialog'
require 'app/views/dialog/fatture_clienti_dialog'
require 'app/views/dialog/tipi_pagamento_dialog'
require 'app/views/dialog/banche_dialog'
require 'app/views/scadenzario/incassi_fattura_cliente_panel'
require 'app/views/scadenzario/fattura_cliente_common_actions'

module Views
  module Scadenzario
    module FatturaClientePanel
      include Views::Scadenzario::FatturaClienteCommonActions

      def ui(container=nil)

        model :cliente => {:attrs => [:denominazione, :p_iva]},
          :fattura_cliente_scadenzario => {:attrs => [:num,
                                            :data_emissione,
                                            :importo,
                                            :nota_di_credito],
                                          :alias => :fattura_cliente}

        controller :scadenzario

        logger.debug('initializing FatturaClientePanel...')
        xrc = Xrc.instance()
        # Fattura cliente

        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_num', self, :extends => TextField) do |field|
          field.evt_char { |evt| txt_num_keypress(evt) }
        end
        xrc.find('txt_data_emissione', self, :extends => DateField) do |field|
          field.move_after_in_tab_order(txt_num)
        end
        xrc.find('txt_importo', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_importo_keypress(evt) }
        end
        xrc.find('btn_pdc', self)
        xrc.find('chk_nota_di_credito', self, :extends => CheckField)

        xrc.find('btn_cliente', self)
        xrc.find('btn_fattura', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)
        xrc.find('btn_indietro', self)

        map_events(self)

        map_text_enter(self, {'txt_importo' => 'on_importo_enter'})

        xrc.find('INCASSI_FATTURA_CLIENTE_PANEL', container,
          :extends => Views::Scadenzario::IncassiFatturaClientePanel,
          :force_parent => self)

        incassi_fattura_cliente_panel.ui()

        subscribe(:evt_dettaglio_incasso) do |incasso|
          self.fattura_cliente = incasso.fattura_cliente_scadenzario # importante deve essere di tipo fattura_cliente_scadenzario
          self.cliente = self.fattura_cliente.cliente
          carica_righe_fattura_pdc()
          transfer_cliente_to_view()
          transfer_fattura_cliente_to_view()
          incassi_fattura_cliente_panel.display_incassi_fattura_cliente(self.fattura_cliente, incasso)
          incassi_fattura_cliente_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_cliente_command_state()
          incassi_fattura_cliente_panel.txt_importo.activate()

        end

        subscribe(:evt_dettaglio_fattura_cliente_scadenzario) do |fattura|
          reset_panel()
          self.fattura_cliente = fattura # importante deve essere di tipo fattura_cliente_scadenzario
          self.cliente = self.fattura_cliente.cliente
          carica_righe_fattura_pdc()
          transfer_cliente_to_view()
          transfer_fattura_cliente_to_view()
          incassi_fattura_cliente_panel.display_incassi_fattura_cliente(self.fattura_cliente)
          incassi_fattura_cliente_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            txt_data_emissione,
            txt_importo,
            chk_nota_di_credito
          ]

          reset_fattura_cliente_command_state()
          incassi_fattura_cliente_panel.txt_importo.activate()

        end

        subscribe(:evt_bilancio_attivo) do |data|
          if configatron.bilancio.attivo || configatron.liquidazioni.attivo
            enable_widgets([btn_pdc])
          else
            disable_widgets([btn_pdc])
          end
        end

        subscribe(:evt_liquidazioni_attivo) do |data|
          if configatron.bilancio.attivo || configatron.liquidazioni.attivo
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
