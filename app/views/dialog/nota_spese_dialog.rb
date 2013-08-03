# encoding: utf-8

module Views
  module Dialog
    class NotaSpeseDialog < Wx::Dialog
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
        
        #set_title("Ricerca #{Models::NotaSpese::INTESTAZIONE_PLURALE[configatron.pre_fattura.intestazione.to_i]}")
        
        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "NOTE_SPESE_DLG")

        # user interface
        xrc.find('chce_anno', self, :extends => ChoiceStringField)
        xrc.find('txt_ricerca', self, :extends => TextField)
        txt_ricerca.activate()
        xrc.find('btn_ricerca', self)
        btn_ricerca.set_default()
        xrc.find('lstrep_note_spese', self, :extends => ReportField)
        xrc.find('wxID_OK', self)
        
        # lista clienti
        
        lstrep_note_spese.column_info([{:caption => 'Cliente', :width => 150},
            {:caption => 'Numero', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 80},
            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}])
        lstrep_note_spese.data_info([{:attr => lambda {|ns| ns.cliente.denominazione }},
            {:attr => :num},
            {:attr => :data_emissione, :format => :date},
            {:attr => :importo, :format => :currency}])

        # carico gli anni contabili
        chce_anno.load_data(ctrl.load_anni_contabili(NotaSpese), 
          :select => :last)

        map_events(self)
        
        transfer_filtro_to_view()
      end

      def btn_ricerca_click(evt)
        Wx::BusyCursor.busy() do
          begin
            transfer_filtro_from_view()
            self.result_set_lstrep_note_spese = ctrl.search_for_note_spese()
            if result_set_lstrep_note_spese.empty?
              Wx::message_box("Nessun record trovato.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
              txt_ricerca.activate() 
            else
              lstrep_note_spese.display(result_set_lstrep_note_spese)
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

      def lstrep_note_spese_item_activated(evt)
        on_confirm(evt)
      end

      def on_confirm(evt)
        if(lstrep_note_spese.get_selected_item_count() == 0)
          Wx::message_box("Selezionare #{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]}.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          txt_ricerca.activate()
          btn_ricerca.set_default()
          evt.skip(false)
        else
          if(self.parent.is_a? Views::Fatturazione::FatturaClientePanel)
            if self.parent.nota_spese_associata? self.selected
              Wx::message_box("#{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} già presente in fattura.",
                'Avvertenza',
                Wx::OK | Wx::ICON_WARNING, self)

              evt.skip(false)
            else
              end_modal(Wx::ID_OK)
            end
          else
            end_modal(Wx::ID_OK)
          end          
        end
      end

    end
  end
end
