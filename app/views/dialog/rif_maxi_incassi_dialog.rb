# encoding: utf-8

module Views
  module Dialog
    class RifMaxiIncassiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, incassi=[])
        super()
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "RIF_MAXI_INCASSI_DLG")

        # user interface
        xrc.find('lstrep_incassi', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista incassi fatture clienti
        
        lstrep_incassi.column_info([{:caption => 'Incasso', :width => 100},
            {:caption => 'Del', :width => 80},
            {:caption => 'Fattura', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Del', :width => 80},
            {:caption => 'Cliente', :width => 140, :align => Wx::LIST_FORMAT_LEFT}])
        lstrep_incassi.data_info([{:attr => :importo, :format => :currency},
            {:attr => :data_pagamento, :format => :date},
            {:attr => lambda {|incasso| incasso.fattura_cliente.num }},
            {:attr => lambda {|incasso| incasso.fattura_cliente.data_emissione }, :format => :date},
            {:attr => lambda {|incasso| incasso.fattura_cliente.cliente.denominazione }}])

        map_events(self)
        
        lstrep_incassi.display(incassi)
      end

      def btn_ok_click(evt)
        if(lstrep_incassi.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un incasso.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          evt.skip(false)
        else
          evt.skip()
        end

      end
      
    end
  end
end
