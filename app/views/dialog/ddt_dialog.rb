# encoding: utf-8

module Views
  module Dialog
    class DdtDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()
        
        model :filtro => {:attrs => [:anno, :ricerca]}
        
        filtro.cliente = parent.cliente()
        
        controller :fatturazione
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "DDT_DLG")

        # user interface
        xrc.find('chce_anno', self, :extends => ChoiceStringField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('lstrep_ddt', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista clienti
        
        lstrep_ddt.column_info([{:caption => 'Cliente', :width => 250},
            {:caption => 'Numero', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80}])
        lstrep_ddt.data_info([{:attr => lambda {|ns| ns.cliente.denominazione }},
            {:attr => :num},
            {:attr => :data_emissione, :format => :date}])

        # carico gli anni contabili
        chce_anno.load_data(ctrl.load_anni_contabili(Ddt), 
          :select => :last)

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        Wx::BusyCursor.busy() do
          begin
            transfer_filtro_from_view()
            self.result_set_lstrep_ddt = ctrl.search_for_ddt()
            if result_set_lstrep_ddt.empty?
              Wx::message_box("Nessun record trovato.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
              txt_ricerca.activate() 
            else
              lstrep_ddt.display(result_set_lstrep_ddt)
            end
          rescue Exception => e
            log_error(self, e)
          end
        end          
        
        evt.skip(false)
      end

      def btn_ok_click(evt)
        on_confirm(evt)
      end

      def lstrep_ddt_item_activated(evt)
        on_confirm(evt)
      end

      def on_confirm(evt)
        if(lstrep_ddt.get_selected_item_count() == 0)
          Wx::message_box("Selezionare un documento di trasporto.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          txt_ricerca.activate()
          btn_ricerca.set_default()
          evt.skip(false)
        else
          end_modal(Wx::ID_OK)
        end
      end

    end
  end
end
