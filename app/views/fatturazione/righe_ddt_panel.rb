# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Fatturazione
    module RigheDdtPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      def ui
        
        model :riga_ddt => {:attrs => [:qta, :descrizione]}
        
        controller :fatturazione

        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_qta', self, :extends => NumericField)
        xrc.find('txt_descrizione', self, :extends => TextField)
                              
        xrc.find('lstrep_righe_ddt', self, :extends => EditableReportField) do |list|
          width = (configatron.screen.width <= 1024 ? 700 : 900)
          list.column_info([{:caption => 'Quantità', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
                            {:caption => 'Descrizione', :width => width}])
          list.data_info([{:attr => :qta},
                          {:attr => :descrizione}])

        end

        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        map_events(self)
        map_text_enter(self, {'txt_qta' => 'on_riga_text_enter', 
                              'txt_descrizione' => 'on_riga_text_enter'})
                          
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
          
          lstrep_righe_ddt.reset()
          self.result_set_lstrep_righe_ddt = []
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def on_riga_text_enter(evt)
        begin
          logger.debug 'enter shooted!'
          if(lstrep_righe_ddt.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_aggiungi_click(evt)
        begin
          if cliente?
            transfer_riga_ddt_from_view()
            if self.riga_ddt.valid?
              self.result_set_lstrep_righe_ddt << self.riga_ddt
              lstrep_righe_ddt.display(self.result_set_lstrep_righe_ddt)
              lstrep_righe_ddt.force_visible(:last)
              reset_gestione_riga()
              txt_qta.activate()
            else
              Wx::message_box(self.riga_ddt.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              
              focus_riga_ddt_error_field()

            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_modifica_click(evt)
        begin
          if cliente?
            transfer_riga_ddt_from_view()
            if self.riga_ddt.valid?
              self.riga_ddt.log_attr()
              lstrep_righe_ddt.display(self.result_set_lstrep_righe_ddt)
              reset_gestione_riga()
              txt_qta.activate()
            else
              Wx::message_box(self.riga_ddt.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              
              focus_riga_ddt_error_field()

            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_elimina_click(evt)
        begin
          if cliente?
            self.riga_ddt.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
            lstrep_righe_ddt.display(self.result_set_lstrep_righe_ddt)
            reset_gestione_riga()
            txt_qta.activate()
          end          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_nuovo_click(evt)
        begin
          if cliente?
            reset_gestione_riga()
            lstrep_righe_ddt.display(self.result_set_lstrep_righe_ddt)
            txt_qta.activate()
          end          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def lstrep_righe_ddt_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_ddt.each do |record|
            if record.ident() == row_id
              self.riga_ddt = record
              break
            end
          end
          transfer_riga_ddt_to_view()
          enable_widgets [btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
          #txt_descrizione.activate()
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_righe_ddt_item_activated(evt)
        txt_qta.activate()
      end

      def display_righe_ddt(ddt)
        self.result_set_lstrep_righe_ddt = ctrl.search_righe_ddt(ddt)
        lstrep_righe_ddt.display(self.result_set_lstrep_righe_ddt)
        reset_gestione_riga()
      end
      
      def cliente?
        return owner.cliente?
      end

      def reset_gestione_riga()
        reset_riga_ddt()
        enable_widgets [btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end
      
      def changed?
        self.result_set_lstrep_righe_ddt.detect { |riga| riga.touched? }
      end
    end

  end
end