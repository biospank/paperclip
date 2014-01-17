# encoding: utf-8

module Views
  module Dialog
    class OrdiniDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()
        
        model :filtro => {:attrs => [:anno, :ricerca]}
        
        filtro.fornitore = parent.fornitore()
        filtro.anno = parent.chce_anno.view_data if parent.respond_to? 'chce_anno'
        
        controller :magazzino
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "ORDINI_DLG")

        # user interface
        xrc.find('chce_anno', self, :extends => ChoiceStringField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('lstrep_ordini', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista ordini
        
        lstrep_ordini.column_info([{:caption => 'Fornitore', :width => 160},
            {:caption => 'Ordine', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80}])
        lstrep_ordini.data_info([{:attr => lambda {|o| o.fornitore.denominazione }},
            {:attr => :num},
            {:attr => :data_emissione, :format => :date}])

        # carico gli anni contabili
        chce_anno.load_data(ctrl.load_anni_contabili(Models::Ordine), 
          :select => :last)

        map_events(self)
        
        transfer_filtro_to_view()
      end

      def btn_ricerca_click(evt)
        Wx::BusyCursor.busy() do
          begin
            transfer_filtro_from_view()
            self.result_set_lstrep_ordini = ctrl.search_for_ordini()
            if result_set_lstrep_ordini.empty?
              Wx::message_box("Nessun record trovato.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
              txt_ricerca.activate() 
            else
              lstrep_ordini.display(result_set_lstrep_ordini)
            end
          rescue Exception => e
            log_error(self, e)
          end
        end          
        
        evt.skip(false)
      end

      def btn_ok_click(evt)
        if(lstrep_ordini.get_selected_item_count() == 0)
          Wx::message_box("Seleziona una fattura.",
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
