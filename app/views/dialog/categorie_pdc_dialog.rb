# encoding: utf-8

module Views
  module Dialog
    class CategoriePdcDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      attr_accessor :owner

      def initialize(parent, attivi = true)
        super()
        
        self.owner = parent

        model :filtro => {:attrs => []}
        controller :prima_nota

        filtro.attive = attivi
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "CATEGORIE_PDC_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('lstrep_categorie_pdc', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista costi/ricavi
        
        lstrep_categorie_pdc.column_info([{:caption => 'Codice', :width => 80},
                                      {:caption => 'Descrizione', :width => 200}])
        lstrep_categorie_pdc.data_info([{:attr => :codice},
                                   {:attr => :descrizione}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_categorie_pdc = ctrl.search_for_categorie_pdc()
        if result_set_lstrep_categorie_pdc.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_categorie_pdc.display(result_set_lstrep_categorie_pdc)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_categorie_pdc.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un elemento.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

          txt_ricerca.activate()
          btn_ricerca.set_default()
          evt.skip(false)
        else
          evt.skip()
        end

      end
      
    end
  end
end
