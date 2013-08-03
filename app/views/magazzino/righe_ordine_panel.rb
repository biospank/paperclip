# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Magazzino
    module RigheOrdinePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui
        
        model :riga_ordine => {:attrs => [:prodotto,
                                          :qta]}
        
        controller :magazzino

        xrc = Xrc.instance()
        
        xrc.find('lku_prodotto', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|prodotto| self.txt_descrizione_prodotto.view_data = (prodotto ? prodotto.descrizione : nil)},
                                :model => :prodotto,
                                :dialog => :prodotti_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW,
                                :folder => Helpers::MagazzinoHelper::WXBRA_ORDINE_FOLDER)
        end

        xrc.find('txt_descrizione_prodotto', self, :extends => TextField)
        xrc.find('txt_qta', self, :extends => NumericField)
        
        xrc.find('lstrep_righe_ordine', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Codice', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Descrizione', :width => 400, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Qta', :width => 60, :align => Wx::LIST_FORMAT_CENTRE}
          ])
          list.data_info([{:attr => lambda {|riga| riga.prodotto.codice}},
            {:attr => lambda {|riga| riga.prodotto.descrizione}},
            {:attr => :qta}
          ])
        end
        
        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        map_events(self)

        map_text_enter(self, {'lku_prodotto' => 'on_riga_text_enter',
                              'txt_qta' => 'on_riga_text_enter'})
                          
      end

      def init_panel()
        begin
          reset_gestione_riga()
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def reset_panel()
        begin
          reset_gestione_riga()
          
          lstrep_righe_ordine.reset()
          self.result_set_lstrep_righe_ordine = []
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def on_riga_text_enter(evt)
        begin
          if(lstrep_righe_ordine.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      # evita la chiamata ad after_change
      # dopo la lookup e alla perdita del focus
      def lku_prodotto_after_change()

      end

      def btn_aggiungi_click(evt)
        begin
          if fornitore?
            transfer_riga_ordine_from_view()
            if self.riga_ordine.valid?
              self.result_set_lstrep_righe_ordine << self.riga_ordine
              lstrep_righe_ordine.display(self.result_set_lstrep_righe_ordine)
              lstrep_righe_ordine.force_visible(:last)
              reset_gestione_riga()
              lku_prodotto.activate()
            else
              Wx::message_box(self.riga_ordine.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_riga_ordine_error_field()

            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_modifica_click(evt)
        begin
          if fornitore?
            if riga_ordine.caricata?
              Wx::message_box("Riga ordine non modificabile, associata ad un carico di magazzino.",
                'Info',
                  Wx::OK | Wx::ICON_WARNING, self)

            else
              transfer_riga_ordine_from_view()
              if self.riga_ordine.valid?
                self.riga_ordine.log_attr()
                lstrep_righe_ordine.display(self.result_set_lstrep_righe_ordine)
                reset_gestione_riga()
                lku_prodotto.activate()
              else
                Wx::message_box(self.riga_ordine.error_msg,
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)

                focus_riga_ordine_error_field()

              end
            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_elimina_click(evt)
        begin
          if fornitore?
            if riga_ordine.caricata?
              Wx::message_box("Riga ordine non modificabile, associata ad un carico di magazzino.",
                'Info',
                  Wx::OK | Wx::ICON_WARNING, self)

            else
              self.riga_ordine.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
              lstrep_righe_ordine.display(self.result_set_lstrep_righe_ordine)
              reset_gestione_riga()
              lku_prodotto.activate()
            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_nuovo_click(evt)
        begin
          if fornitore?
            reset_gestione_riga()
            # serve ad eliminare l'eventuale focus dalla lista
            # evita che rimanga selezionato un elemento della lista
            lstrep_righe_ordine.display(self.result_set_lstrep_righe_ordine)
            lku_prodotto.activate()
          end          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def lstrep_righe_ordine_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_ordine.each do |record|
            if record.ident() == row_id
              self.riga_ordine = record
              break
            end
          end
          transfer_riga_ordine_to_view()
          update_riga_ui()
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_righe_ordine_item_activated(evt)
        lku_prodotto.activate()
      end

      def display_righe_ordine(ordine, riga = nil)
        self.result_set_lstrep_righe_ordine = ctrl.search_righe_ordine(ordine)
        lstrep_righe_ordine.display(self.result_set_lstrep_righe_ordine)
        reset_gestione_riga()
        if riga
          self.result_set_lstrep_righe_ordine.each_with_index do |record, index|
            if record.id == riga.id
              self.riga_ordine = record
              lstrep_righe_ordine.set_item_state(index, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED)
#              set_focus()
              break
            end
          end
          transfer_riga_ordine_to_view()
          update_riga_ui()
        end
      end
      
      def reset_gestione_riga()
        reset_riga_ordine()
        enable_widgets [lku_prodotto, txt_qta,
                        btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end
      
      def update_riga_ui()
        if  self.riga_ordine.new_record?
          disable_widgets [btn_modifica, btn_elimina]
        else
          enable_widgets [btn_modifica, btn_elimina, btn_aggiungi, btn_nuovo]
        end
      end

      def fornitore?
        return owner.fornitore?
      end

    end
  end
end