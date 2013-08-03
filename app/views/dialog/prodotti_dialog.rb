# encoding: utf-8

module Views
  module Dialog
    class ProdottiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attivi = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :magazzino

        filtro.attivi = attivi

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "PRODOTTI_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuovo', self)
        xrc.find('lstrep_prodotti', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista prodotti
        
        lstrep_prodotti.column_info([{:caption => 'Codice', :width => 80},
                                      {:caption => 'Descrizione', :width => 300}])
        lstrep_prodotti.data_info([{:attr => :codice},
                                   {:attr => :descrizione}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_prodotti = ctrl.search_for_prodotti()
        if result_set_lstrep_prodotti.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_prodotti.display(result_set_lstrep_prodotti)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_prodotti.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un prodotto.",
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
