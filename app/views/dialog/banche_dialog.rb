# encoding: utf-8

module Views
  module Dialog
    class BancheDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attive = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :configurazione

        filtro.attive = attive

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "BANCHE_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuova', self)
        xrc.find('lstrep_banche', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista banche
        
        lstrep_banche.column_info([{:caption => 'Codice', :width => 80},
                                      {:caption => 'Descrizione', :width => 300}])
        lstrep_banche.data_info([{:attr => :codice},
                                   {:attr => :descrizione}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_banche = ctrl.search_for_banche()
        if result_set_lstrep_banche.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_banche.display(result_set_lstrep_banche)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_banche.get_selected_item_count() == 0)
          Wx::message_box("Seleziona una banca.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

          txt_ricerca.activate()
          btn_ricerca.set_default()
          evt.skip(false)
        else
          evt.skip()
        end

      end
      
      def btn_nuova_click(evt)
        end_modal(btn_nuova.get_id)
      end

    end
  end
end
