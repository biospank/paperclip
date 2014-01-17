# encoding: utf-8

module Views
  module Dialog
    class IncassiRicorrentiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, attivi = true)
        super()
        
        model :filtro => {:attrs => []}
        controller :fatturazione

        filtro.attivi = attivi
        filtro.cliente = parent.cliente()

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "INCASSI_RICORRENTI_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuovo', self)
        xrc.find('lstrep_incassi_ricorrenti', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista incassi_ricorrenti
        
        lstrep_incassi_ricorrenti.column_info([{:caption => 'Cliente', :width => 150},
                                                {:caption => 'Descrizione', :width => 150},
                                                {:caption => 'Importo', :width => 80, :align => Wx::LIST_FORMAT_RIGHT}])
        lstrep_incassi_ricorrenti.data_info([{:attr => lambda {|ir| ir.cliente.denominazione}},
                                   {:attr => :descrizione},
                                   {:attr => :importo, :format => :currency}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_incassi_ricorrenti = ctrl.search_for_incassi_ricorrenti()
        if result_set_lstrep_incassi_ricorrenti.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_incassi_ricorrenti.display(result_set_lstrep_incassi_ricorrenti)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_incassi_ricorrenti.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un incasso.",
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
