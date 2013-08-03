# encoding: utf-8

module Views
  module Dialog
    class FattureFornitoriDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()
        
        model :filtro => {:attrs => [:anno, :ricerca]}
        
        filtro.fornitore = parent.fornitore()
        filtro.sql_criteria = parent.dialog_sql_criteria()
        
        controller :fatturazione
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "FATTURE_FORNITORI_DLG")

        # user interface
        xrc.find('chce_anno', self, :extends => ChoiceStringField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('lstrep_fatture_fornitori', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista fornitori
        
        lstrep_fatture_fornitori.column_info([{:caption => 'Fornitore', :width => 160},
            {:caption => 'Fattura', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'N.C.', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80},
            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
        lstrep_fatture_fornitori.data_info([{:attr => lambda {|ff| ff.fornitore.denominazione }},
            {:attr => :num, :if => lambda {|ff| !ff.nota_di_credito?}},
            {:attr => :num, :if => lambda {|ff| ff.nota_di_credito?}},
            {:attr => :data_emissione, :format => :date},
            {:attr => :importo, :format => :currency}])

        # carico gli anni contabili
        chce_anno.load_data(ctrl.load_anni_contabili(FatturaFornitore), 
          :select => :last)

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        Wx::BusyCursor.busy() do
          begin
            transfer_filtro_from_view()
            self.result_set_lstrep_fatture_fornitori = ctrl.search_for_fatture_fornitori()
            if result_set_lstrep_fatture_fornitori.empty?
              Wx::message_box("Nessun record trovato.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
              txt_ricerca.activate() 
            else
              lstrep_fatture_fornitori.display(result_set_lstrep_fatture_fornitori)
            end
          rescue Exception => e
            log_error(self, e)
          end
        end          
        
        evt.skip(false)
      end

      def btn_ok_click(evt)
        if(lstrep_fatture_fornitori.get_selected_item_count() == 0)
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
