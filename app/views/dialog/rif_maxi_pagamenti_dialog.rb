# encoding: utf-8

module Views
  module Dialog
    class RifMaxiPagamentiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent, pagamenti=[])
        super()
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "RIF_MAXI_PAGAMENTI_DLG")

        # user interface
        xrc.find('lstrep_pagamenti', self, :extends => ReportField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista pagamenti fatture fornitori
        
        lstrep_pagamenti.column_info([{:caption => 'Pagamento', :width => 100},
            {:caption => 'Del', :width => 80},
            {:caption => 'Fattura', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Del', :width => 80},
            {:caption => 'Cliente', :width => 140, :align => Wx::LIST_FORMAT_LEFT}])
        lstrep_pagamenti.data_info([{:attr => :importo, :format => :currency},
            {:attr => :data_pagamento, :format => :date},
            {:attr => lambda {|incasso| incasso.fattura_fornitore.num }},
            {:attr => lambda {|incasso| incasso.fattura_fornitore.data_emissione }, :format => :date},
            {:attr => lambda {|incasso| incasso.fattura_fornitore.fornitore.denominazione }}])

        map_events(self)
        
        lstrep_pagamenti.display(pagamenti)
      end

      def btn_ok_click(evt)
        if(lstrep_pagamenti.get_selected_item_count() == 0)
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
