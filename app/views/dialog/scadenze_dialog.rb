# encoding: utf-8

module Views
  module Dialog
    class ScadenzeDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      
      attr_accessor :selected_incasso, :selected_pagamento
      
      def initialize(parent)
        super()
        
        controller :scadenzario

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "SCADENZE_DLG")

        xrc.find('lstrep_scadenze_incassi', self, :extends => ReportField) do |list|
          list.column_info([
            {:caption => 'Cliente', :width => 200},
            {:caption => 'Fattura', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Importo', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Incasso', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Scadenza', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Modalità', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Note', :width => 200, :align => Wx::LIST_FORMAT_LEFT}
          ])
          list.data_info([
            {:attr => lambda {|incasso| incasso.fattura_cliente.cliente.denominazione}},
            {:attr => lambda {|incasso| incasso.fattura_cliente.num}},
            {:attr => lambda {|incasso| incasso.fattura_cliente.importo}, :format => :currency},
            {:attr => lambda {|incasso| incasso.importo}, :format => :currency},
            {:attr => :data_pagamento, :format => :date},
            {:attr => lambda {|incasso| (incasso.tipo_pagamento ? incasso.tipo_pagamento.descrizione : '')}},
            {:attr => :note}
          ])
        end
        
        xrc.find('lstrep_scadenze_pagamenti', self, :extends => ReportField) do |list|
          list.column_info([
            {:caption => 'Fornitore', :width => 200},
            {:caption => 'Fattura', :width => 60, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Importo', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Pagamento', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Scadenza', :width => 80, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Modalità', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Note', :width => 200, :align => Wx::LIST_FORMAT_LEFT}
          ])
          list.data_info([
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.fornitore.denominazione}},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.num}},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.importo}, :format => :currency},
            {:attr => lambda {|pagamento| pagamento.importo}, :format => :currency},
            {:attr => :data_pagamento, :format => :date},
            {:attr => lambda {|pagamento| (pagamento.tipo_pagamento ? pagamento.tipo_pagamento.descrizione : '')}},
            {:attr => :note}
          ])
        end
        
        xrc.find('btn_dettaglio_incasso', self)
        xrc.find('btn_conferma_incassi', self)
        xrc.find('btn_dettaglio_pagamento', self)
        xrc.find('btn_conferma_pagamenti', self)

        map_events(self)

        evt_close() {|evt| on_close(evt) }
        
        #enable_close_button(false)
        
        init_panel()
        
      end

      def init_panel()
        begin
          display_incassi_in_sospeso()        
          display_pagamenti_in_sospeso()        
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def reset_panel()
        begin

          lstrep_scadenze_incassi.reset()
          self.result_set_lstrep_scadenze_incassi = []
          lstrep_scadenze_pagamenti.reset()
          self.result_set_lstrep_scadenze_pagamenti = []

        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def display_incassi_in_sospeso()
        self.result_set_lstrep_scadenze_incassi = ctrl.incassi_sospesi()
        lstrep_scadenze_incassi.display(self.result_set_lstrep_scadenze_incassi)
      end
      
      def display_pagamenti_in_sospeso()
        self.result_set_lstrep_scadenze_pagamenti = ctrl.pagamenti_sospesi()
        lstrep_scadenze_pagamenti.display(self.result_set_lstrep_scadenze_pagamenti)
      end
      
      def btn_conferma_incassi_click(evt)
        begin
          res = Wx::message_box("Confermi la chiusura di tutti gli incassi in sospeso?",
            'Domanda',
            Wx::OK | Wx::CANCEL | Wx::ICON_QUESTION, self)

          if res == Wx::OK
            Wx::BusyCursor.busy() do
              ctrl.salva_incassi_in_sospeso()
              ctrl.carica_movimenti_in_sospeso()
            end
            if ctrl.movimenti_in_sospeso?
              display_incassi_in_sospeso()
            else
              end_modal(Wx::ID_CANCEL)
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_conferma_pagamenti_click(evt)
        begin
          res = Wx::message_box("Confermi la chiusura di tutti i pagamenti in sospeso?",
            'Domanda',
            Wx::OK | Wx::CANCEL | Wx::ICON_QUESTION, self)

          if res == Wx::OK
            Wx::BusyCursor.busy() do
              ctrl.salva_pagamenti_in_sospeso()
              ctrl.carica_movimenti_in_sospeso()
            end
            if ctrl.movimenti_in_sospeso?
              display_pagamenti_in_sospeso()
            else
              end_modal(Wx::ID_CANCEL)
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_dettaglio_incasso_click(evt)
        dettaglio_incasso(evt)
      end
      
      def btn_dettaglio_pagamento_click(evt)
        dettaglio_pagamento(evt)
      end
      
      def lstrep_scadenze_incassi_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_scadenze_incassi.each do |record|
            if record.id == row_id
              self.selected_incasso = record.id
              logger.debug("Selected: #{self.selected_incasso}")
              break
            end
          end
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_scadenze_pagamenti_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_scadenze_pagamenti.each do |record|
            if record.id == row_id
              self.selected_pagamento = record.id
              logger.debug("Selected: #{self.selected_pagamento}")
              break
            end
          end
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_scadenze_incassi_item_activated(evt)
        dettaglio_incasso(evt)
      end

      def lstrep_scadenze_pagamenti_item_activated(evt)
        dettaglio_pagamento(evt)
      end

      def dettaglio_incasso(evt)
        begin
          if(lstrep_scadenze_incassi.get_selected_item_count() == 0)
            Wx::message_box("Seleziona un incasso.",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            evt.skip(false)
          else
            self.selected = ctrl.load_incasso(self.selected_incasso)
            end_modal(Wx::ID_OK)
          end
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def dettaglio_pagamento(evt)
        begin
          if(lstrep_scadenze_pagamenti.get_selected_item_count() == 0)
            Wx::message_box("Seleziona un pagamento.",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            evt.skip(false)
          else
            self.selected = ctrl.load_pagamento(self.selected_pagamento)
            end_modal(Wx::ID_OK)
          end
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def on_close(evt)
        res = Wx::message_box("La finestra dei movimenti in scadenza verrà riproposta ogni 5 min.\nConfermi la chiusura?",
          'Domanda',
          Wx::OK | Wx::CANCEL | Wx::ICON_QUESTION, self)

        if res == Wx::OK
          end_modal(Wx::ID_EXIT)
        end
        
      end
    end
  end
end
