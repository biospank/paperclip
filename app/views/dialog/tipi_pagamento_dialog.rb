# encoding: utf-8

module Views
  module Dialog
    class TipiPagamentoDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attivi = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :scadenzario

        filtro.attivi = attivi
        filtro.categoria = parent.categoria

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "TIPI_PAGAMENTO_DLG")
        
        if parent.categoria == Helpers::AnagraficaHelper::FORNITORI
          self.title = "Ricerca modalità pagamento"
        else
          self.title = "Ricerca modalità incasso"
        end
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuovo', self)
        xrc.find('lstrep_tipi_pagamento', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista tipi pagamento
        
        lstrep_tipi_pagamento.column_info([{:caption => 'Codice', :width => 80},
                                     {:caption => 'Descrizione', :width => 200}])
        lstrep_tipi_pagamento.data_info([{:attr => :codice},
                                   {:attr => :descrizione}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_tipi_pagamento = ctrl.search_for_tipi_pagamento()
        if result_set_lstrep_tipi_pagamento.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_tipi_pagamento.display(result_set_lstrep_tipi_pagamento)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_tipi_pagamento.get_selected_item_count() == 0)
          Wx::message_box("Seleziona una ritenuta.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

          txt_ricerca.activate()
          btn_ricerca.set_default()
          evt.skip(false)
        else
          evt.skip()
        end

      end
      
      def btn_nuovo_click(evt)
        end_modal(btn_nuovo.get_id)
      end

    end
  end
end
