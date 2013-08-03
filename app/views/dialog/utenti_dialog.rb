# encoding: utf-8

module Views
  module Dialog
    class UtentiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()
        
        model :filtro => {:attrs => []}
        controller :configurazione

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "UTENTI_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('lstrep_utenti', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista utenti
        
        lstrep_utenti.column_info([{:caption => 'Utenti', :width => 100}])
        lstrep_utenti.data_info([{:attr => :login}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_utenti = ctrl.search_for_utenti()
        if result_set_lstrep_utenti.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_utenti.display(result_set_lstrep_utenti)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_utenti.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un utente.",
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
