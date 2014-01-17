# encoding: utf-8

module Views
  module Dialog
    class PdcDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      attr_accessor :owner

      def initialize(parent, attivi = true)
        super()
        
        self.owner = parent

        model :filtro => {:attrs => []}
        controller :prima_nota

        filtro.attivi = attivi
        filtro.sql_criteria = parent.dialog_sql_criteria() if parent.respond_to? :dialog_sql_criteria
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "PDC_DLG")

        # user interface
        #@txt_ricerca = xrc.find('txt_ricerca', self, TextField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('btn_nuovo', self)
        xrc.find('lstrep_pdc', self, :extends => ReportField)
        xrc.find('chk_tutti', self, :extends => CheckField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        
        # lista costi/ricavi
        
        lstrep_pdc.column_info([{:caption => 'Codice', :width => 80},
                                      {:caption => 'Descrizione', :width => 200},
                                      {:caption => 'Tipo', :width => 100}])
        lstrep_pdc.data_info([{:attr => :codice},
                                   {:attr => :descrizione},
                                   {:attr => :type}])

        map_events(self)
        
      end

      def btn_ricerca_click(evt)
        transfer_filtro_from_view()
        self.result_set_lstrep_pdc = ctrl.search_for_pdc()
        if result_set_lstrep_pdc.empty?
          Wx::message_box("Nessun record trovato.",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
          txt_ricerca.activate() 
        else
          lstrep_pdc.display(result_set_lstrep_pdc)
        end
      end

      def btn_ok_click(evt)
        if(lstrep_pdc.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un elemento.",
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

      def chk_tutti_click(evt)
        if chk_tutti.checked?
          filtro.sql_criteria = nil
        else
          filtro.sql_criteria = self.owner.dialog_sql_criteria() if self.owner.respond_to? :dialog_sql_criteria
        end
        btn_ricerca_click(evt)
      end

    end
  end
end
