# encoding: utf-8


module Views
  module Dialog
    class FornitoriDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attivi = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :anagrafica

        filtro.attivi = attivi

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "FORNITORI_DLG")

        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuovo', self)
        xrc.find('lstrep_fornitori', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista clienti
        
        lstrep_fornitori.column_info([{:caption => 'Nominativo', :width => 180},
                                     {:caption => 'Cod. fisc.', :width => 140},
                                     {:caption => 'Partita iva'}])
        lstrep_fornitori.data_info([{:attr => :denominazione},
                                   {:attr => :cod_fisc},
                                   {:attr => :p_iva}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_fornitori = ctrl.search_for_fornitori()
        if result_set_lstrep_fornitori.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_fornitori.display(result_set_lstrep_fornitori)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_fornitori.get_selected_item_count() == 0)
          Wx::message_box('Seleziona un fornitore.',
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
