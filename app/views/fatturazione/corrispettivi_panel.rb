# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/fatturazione/corrispettivi_common_actions'
require 'app/views/fatturazione/righe_corrispettivi_panel'

module Views
  module Fatturazione
    module CorrispettiviPanel
      include Views::Fatturazione::CorrispettiviCommonActions

      def ui(container=nil)

        model :filtro => {:attrs => []}

        controller :fatturazione

        logger.debug('initializing CorrispettiviPanel...')
        xrc = Xrc.instance()
        # Corrispettivi

        xrc.find('chce_anno', self, :extends => ChoiceStringField) do |chce|
          # carico gli anni contabili
          chce.load_data(ctrl.load_anni_contabili(Models::Corrispettivo, 'data'),
            :select => :last)
        end

        subscribe(:evt_anni_contabili_corrispettivi_changed) do |data|
          chce_anno.load_data(data,
            :select => :last)
        end

        xrc.find('chce_mese', self, :extends => ChoiceField) do |chce|
          chce.load_data(Helpers::ApplicationHelper::MESI,
            :label => :descrizione,
            :select => (Date.today.month - 1))
        end

        xrc.find('lku_aliquota', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|aliquota| self.txt_descrizione_aliquota.view_data = (aliquota ? aliquota.descrizione : nil)},
                                :model => :aliquota,
                                :dialog => :aliquote_dialog,
                                :default => lambda {|aliquota| aliquota.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
        end

        xrc.find('txt_descrizione_aliquota', self, :extends => TextField)

# chce_aliquota (esempio di implementazione con gestione del default)
#        xrc.find('chce_aliquota', self, :extends => ChoiceField)
#
#        subscribe(:evt_aliquota_changed) do |data|
#          chce_aliquota.load_data(data,
#                  :label => :descrizione,
#                  :if => lambda {|aliquota| aliquota.attiva?},
#                  :select => :default,
#                  :default => (data.detect { |aliquota| aliquota.predefinita? }) || data.first)
#        end

        subscribe(:evt_aliquota_changed) do |data|
          lku_aliquota.load_data(data)
          lku_aliquota.set_default()
        end

        xrc.find('btn_salva', self)

        map_events(self)

        xrc.find('RIGHE_CORRISPETTIVI_PANEL', container,
          :extends => Views::Fatturazione::RigheCorrispettiviPanel,
          :force_parent => self)

        righe_corrispettivi_panel.ui()

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_load_corrispettivi) do
          transfer_filtro_from_view()
          corrispettivi = ctrl.search_corrispettivi()
          righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
          righe_corrispettivi_panel.riepilogo_corrispettivi()
          righe_corrispettivi_panel.init_panel()
        end

        subscribe(:evt_dettaglio_corrispettivo) do |corrispettivo|
          reset_panel()
          chce_anno.view_data = corrispettivo.data.year
          chce_mese.view_data = ("%02d" % corrispettivo.data.month)
          transfer_filtro_from_view()
          corrispettivi = ctrl.search_corrispettivi()
          righe_corrispettivi_panel.display_righe_corrispettivi(corrispettivi)
          righe_corrispettivi_panel.riepilogo_corrispettivi()
          righe_corrispettivi_panel.init_panel()
        end

      end

    end
  end
end
