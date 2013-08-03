# encoding: utf-8

module Views
  module Dialog
    class CausaliDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attive = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :prima_nota

        filtro.attive = attive

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "CAUSALI_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuova', self)
        xrc.find('lstrep_causali', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista causali
        
        lstrep_causali.column_info([{:caption => 'Codice', :width => 80},
                                      {:caption => 'Descrizione', :width => 300}])
        lstrep_causali.data_info([{:attr => :codice},
                                   {:attr => :descrizione}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_causali = ctrl.search_for_causali()
        if result_set_lstrep_causali.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_causali.display(result_set_lstrep_causali)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_causali.get_selected_item_count() == 0)
          Wx::message_box("Seleziona una causale.",
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
