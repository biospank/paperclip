# encoding: utf-8

module Views
  module Dialog
    class NormaDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attive = true, allow_new = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :scadenzario

        filtro.attive = attive

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "NORMA_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuova', self) do |btn|
          btn.hide() unless allow_new
        end
        xrc.find('lstrep_norma', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista norma
        
        lstrep_norma.column_info([{:caption => 'Codice', :width => 80},
                                     {:caption => '%', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
                                     {:caption => 'Descrizione', :width => 180}])
        lstrep_norma.data_info([{:attr => :codice},
                                   {:attr => :percentuale, :format => :percentage},
                                   {:attr => :descrizione}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_norma = ctrl.search_for_norma()
        if result_set_lstrep_norma.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_norma.display(result_set_lstrep_norma)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_norma.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un elemento dalla lista.",
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
