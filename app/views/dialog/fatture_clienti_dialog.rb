# encoding: utf-8

module Views
  module Dialog
    class FattureClientiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()
        
        model :filtro => {:attrs => [:anno, :ricerca]}
        
        filtro.cliente = parent.cliente()
        filtro.sql_criteria = parent.dialog_sql_criteria()
        filtro.anno = parent.chce_anno.view_data if parent.respond_to? 'chce_anno'
        
        controller :fatturazione
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "FATTURE_CLIENTI_DLG")

        # user interface
        xrc.find('chce_anno', self, :extends => ChoiceStringField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('lstrep_fatture_clienti', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista clienti
        
        lstrep_fatture_clienti.column_info([{:caption => 'Cliente', :width => 160},
            {:caption => 'Fattura', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'N.C.', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80},
            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
        lstrep_fatture_clienti.data_info([{:attr => lambda {|fc| fc.cliente.denominazione }},
            {:attr => :num, :if => lambda {|fc| !fc.nota_di_credito?}},
            {:attr => :num, :if => lambda {|fc| fc.nota_di_credito?}},
            {:attr => :data_emissione, :format => :date},
            {:attr => :importo, :format => :currency}])

        # carico gli anni contabili
        chce_anno.load_data(ctrl.load_anni_contabili(FatturaCliente), 
          :select => :last)

        map_events(self)
        
        transfer_filtro_to_view()
      end

      def btn_ricerca_click(evt)
        Wx::BusyCursor.busy() do
          begin
            transfer_filtro_from_view()
            self.result_set_lstrep_fatture_clienti = ctrl.search_for_fatture_clienti()
            if result_set_lstrep_fatture_clienti.empty?
              Wx::message_box("Nessun record trovato.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
              txt_ricerca.activate() 
            else
              lstrep_fatture_clienti.display(result_set_lstrep_fatture_clienti)
            end
          rescue Exception => e
            log_error(self, e)
          end
        end          
        
        evt.skip(false)
      end

      def btn_ok_click(evt)
        if(lstrep_fatture_clienti.get_selected_item_count() == 0)
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
