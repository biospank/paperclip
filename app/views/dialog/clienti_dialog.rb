# encoding: utf-8

module Views
  module Dialog
    class ClientiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attivi = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :anagrafica

        filtro.attivi = attivi

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "CLIENTI_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuovo', self)
        xrc.find('lstrep_clienti', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista clienti
        
        lstrep_clienti.column_info([{:caption => 'Nominativo', :width => 180},
                                     {:caption => 'Cod. fisc.', :width => 140},
                                     {:caption => 'Partita iva'}])
        lstrep_clienti.data_info([{:attr => :denominazione},
                                   {:attr => :cod_fisc},
                                   {:attr => :p_iva}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_clienti = ctrl.search_for_clienti()
        if result_set_lstrep_clienti.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_clienti.display(result_set_lstrep_clienti)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_clienti.get_selected_item_count() == 0)
          Wx::message_box('Seleziona un cliente.',
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
