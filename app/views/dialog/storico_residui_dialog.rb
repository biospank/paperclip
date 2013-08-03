# encoding: utf-8

module Views
  module Dialog
    class StoricoResiduiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()
        
        model :filtro => {:attrs => [:anno]}
        
        controller :prima_nota
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "STORICO_RESIDUI_DLG")

        # user interface
        xrc.find('chce_anno', self, :extends => ChoiceStringField)
        xrc.find('btn_ricerca', self) do |btn|
          btn.set_default()
        end
        xrc.find('lstrep_storico_residui', self, :extends => EditableReportField)
        
        lstrep_storico_residui.column_info([{:caption => 'Data stampa definitivo', :width => 300}])
        lstrep_storico_residui.data_info([{:attr => :data_residuo, :format => :date}])

        xrc.find('wxID_OK', self)
        
        # carico gli anni contabili
        chce_anno.load_data(ctrl.load_anni_contabili(Scrittura, 'data_residuo'), 
          :select => :last)

        map_events(self)
        
      end

      def lstrep_storico_residui_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_storico_residui.each do |record|
            if record.ident() == row_id
              self.selected = record.data_residuo
              logger.debug("Selected: #{self.selected}")
              break
            end
          end
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def btn_ricerca_click(evt)
        Wx::BusyCursor.busy() do
          begin
            transfer_filtro_from_view()
            self.result_set_lstrep_storico_residui = ctrl.search_storico_residui()
            if result_set_lstrep_storico_residui.empty?
              Wx::message_box("Nessun record trovato.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
              chce_anno.activate() 
            else
              lstrep_storico_residui.display(result_set_lstrep_storico_residui)
            end
          rescue Exception => e
            log_error(self, e)
          end
        end          
        
        evt.skip(false)
      end

      def btn_ok_click(evt)
        if(lstrep_storico_residui.get_selected_item_count() == 0)
          Wx::message_box("Seleziona uno storico.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          btn_ricerca.set_default()
          evt.skip(false)
        else
          evt.skip()
        end

      end
      
    end
  end
end
