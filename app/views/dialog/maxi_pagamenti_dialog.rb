# encoding: utf-8

module Views
  module Dialog
    class MaxiPagamentiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      WX_ID_F2 = Wx::ID_ANY

      attr_accessor :owner
      
      def initialize(parent)
        super()
        
        self.owner = parent
        
        model :maxi_pagamento_fornitore => {:attrs => [:importo,
          :tipo_pagamento,
          :banca,
          :data_pagamento,
          :note],
          :alias => :maxi_pagamento}
        
        controller :scadenzario

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "MAXI_PAGAMENTI_DLG")

        xrc.find('txt_importo', self, :extends => DecimalField)
        xrc.find('lku_tipo_pagamento', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|tipo_pagamento| self.txt_descrizione_tipo_pagamento.view_data = (tipo_pagamento ? tipo_pagamento.descrizione : nil)},
                                :model => :tipo_pagamento,
                                :dialog => :tipi_pagamento_dialog,
                                :default => lambda {|tipo_pagamento| tipo_pagamento.predefinito?},
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
        end

        subscribe(:evt_tipo_pagamento_fornitore_changed) do |data|
          lku_tipo_pagamento.load_data(data)
        end

        xrc.find('txt_descrizione_tipo_pagamento', self, :extends => TextField)
        
        xrc.find('lku_banca', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|banca| self.txt_descrizione_banca.view_data = (banca ? banca.descrizione : nil)},
                                :model => :banca,
                                :dialog => :banche_dialog,
                                :default => lambda {|banca| banca.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
        end
        
        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)
        xrc.find('txt_data_pagamento', self, :extends => DateField)
        xrc.find('txt_note', self, :extends => TextField)
        
        xrc.find('lstrep_maxi_pagamenti', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Tipo', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Banca', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Data', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Note', :width => 250, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Residuo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
          ])
          list.data_info([{:attr => :importo, :format => :currency},
            {:attr => lambda {|pagamento| (pagamento.tipo_pagamento ? pagamento.tipo_pagamento.descrizione : '')}},
            {:attr => lambda {|pagamento| (pagamento.banca ? pagamento.banca.descrizione : '')}},
            {:attr => :data_pagamento, :format => :date},
            {:attr => :note},
            {:attr => lambda {|pagamento| (pagamento.residuo)}, :format => :currency}
          ])
        end
        
        evt_menu(WX_ID_F2) do
          lstrep_maxi_pagamenti.activate()
        end

        evt_new do | evt |
          case evt.data[:subject]
          when :tipo_pagamento
            end_modal(lku_tipo_pagamento.get_id)
          when :banca
            end_modal(lku_banca.get_id)
          end
        end

        xrc.find('lstrep_fatture_collegate', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Fornitore', :width => 400},
            {:caption => 'Fattura', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 120, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Importo', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Parziale', :width => 120, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => lambda {|pagamento| pagamento.fattura_fornitore.fornitore.denominazione}},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.num}},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.data_emissione}, :format => :date},
            {:attr => lambda {|pagamento| pagamento.fattura_fornitore.importo}, :format => :currency},
            {:attr => lambda {|pagamento| (pagamento.importo)}, :format => :currency}
          ])
        end
        
        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)
        xrc.find('wxID_OK', self)

        map_events(self)

        map_text_enter(self, {'txt_importo' => 'on_riga_text_enter',
                              'txt_data_pagamento' => 'on_riga_text_enter',
                              'lku_tipo_pagamento' => 'on_riga_text_enter',
                              'lku_banca' => 'on_riga_text_enter',
                              'txt_note' => 'on_riga_text_enter'})
                          
        lku_tipo_pagamento.load_data(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::FORNITORI))
        
        lku_banca.load_data(ctrl.search_banche())
        
        init_panel()

        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_panel()
        begin
          display_maxi_pagamenti()        
          reset_gestione_riga()
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def reset_panel()
        begin
          reset_gestione_riga()
          
          lstrep_maxi_pagamenti.reset()
          self.result_set_lstrep_maxi_pagamenti = []
          reset_liste_collegate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # sovrascritto per chiamare il metodo load_tipo_pagamento_cliente
      def lku_tipo_pagamento_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            dlg = Views::Dialog::TipiPagamentoDialog.new(self)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_tipo_pagamento.view_data = ctrl.load_tipo_pagamento_fornitore(dlg.selected)
              lku_tipo_pagamento_after_change()
            elsif answer == dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:tipo_pagamento,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER
                ]
              )
              # This sends the event for processing by listeners
              process_event(evt_new)
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end
      end
      
      def lku_tipo_pagamento_after_change()
        begin
          tipo_pagamento = lku_tipo_pagamento.match_selection()
          collega_banca_al tipo_pagamento
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def lku_tipo_pagamento_loose_focus()
        begin
          if tipo_pagamento = lku_tipo_pagamento.match_selection()
            if lku_banca.view_data.nil?
              collega_banca_al tipo_pagamento
            end
          else
            lku_banca.view_data = nil
          end
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def on_riga_text_enter(evt)
        begin
          if(lstrep_maxi_pagamenti.get_selected_item_count() > 0)
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
          transfer_maxi_pagamento_from_view()
          if maxi_pagamento_compatibile?
            if self.maxi_pagamento.valid?
              Wx::BusyCursor.busy() do
                ctrl.save_maxi_pagamento()
                display_maxi_pagamenti()
                lstrep_maxi_pagamenti.force_visible(:last)
                reset_gestione_riga()
                reset_liste_collegate()
                txt_importo.activate()
              end
            else
              Wx::message_box(self.maxi_pagamento.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_maxi_pagamento_error_field()

            end
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)
          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_modifica_click(evt)
        begin
          transfer_maxi_pagamento_from_view()
          if maxi_pagamento_modificabile? and maxi_pagamento_compatibile?
            if self.maxi_pagamento.valid?
              Wx::BusyCursor.busy() do
                ctrl.save_maxi_pagamento()
                display_maxi_pagamenti()
                reset_gestione_riga()
                reset_liste_collegate()
                txt_importo.activate()
              end
            else
              Wx::message_box(self.maxi_pagamento.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_maxi_pagamento_error_field()

            end
          end          
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)
          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_elimina_click(evt)
        begin
          if maxi_pagamento_modificabile?
            transfer_maxi_pagamento_from_view()
            Wx::BusyCursor.busy() do
              ctrl.delete_maxi_pagamento()
              display_maxi_pagamenti()
              reset_gestione_riga()
              reset_liste_collegate()
              txt_importo.activate()
            end
          end          
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("I dati sono stati modificati da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)
          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_nuovo_click(evt)
        begin
          reset_gestione_riga()
          # serve ad eliminare l'eventuale focus dalla lista
          # evita che rimanga selezionato un elemento della lista
          lstrep_maxi_pagamenti.display(self.result_set_lstrep_maxi_pagamenti)
          reset_liste_collegate()
          txt_importo.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def lstrep_maxi_pagamenti_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_maxi_pagamenti.each do |record|
            if record.ident() == row_id
              self.maxi_pagamento = record
              self.selected = self.maxi_pagamento.id
              logger.debug("Selected: #{self.selected}")
              break
            end
          end
          transfer_maxi_pagamento_to_view()
          reset_liste_collegate()
          display_fatture_collegate()
          enable_widgets [btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_fatture_collegate_item_selected(evt)
        # noop
        # evita la valorizzazione della variabile selected
      end

      def display_maxi_pagamenti()
        self.result_set_lstrep_maxi_pagamenti = ctrl.search_maxi_pagamenti()
        calcola_residui_pendenti()
        lstrep_maxi_pagamenti.display(self.result_set_lstrep_maxi_pagamenti)
      end
      
      def display_fatture_collegate()
        self.result_set_lstrep_fatture_collegate = self.maxi_pagamento.pagamenti_fattura_fornitore
        lstrep_fatture_collegate.display(self.result_set_lstrep_fatture_collegate, :ignore_focus => true)
      end
      
      def reset_gestione_riga()
        reset_maxi_pagamento()
        tipo_pagamento = lku_tipo_pagamento.set_default()
        collega_banca_al tipo_pagamento
        # imposto la data di oggi
        txt_data_pagamento.view_data = Date.today
        enable_widgets [btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end
      
      def btn_ok_click(evt)
        on_confirm(evt)
      end

      def lstrep_maxi_pagamenti_item_activated(evt)
        on_confirm(evt)
      end

      def on_confirm(evt)
        if(lstrep_maxi_pagamenti.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un pagamento.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
          evt.skip(false)
        else
          if utilizzato_in_fattura?
            Wx::message_box("La riga selezionata e' gia' utilizzata in fattura",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            evt.skip(false)
          else
            end_modal(Wx::ID_OK)
          end
        end
      end
      
      def maxi_pagamento_modificabile?()
        if(((!self.maxi_pagamento.pagamenti_fattura_fornitore.blank?) or utilizzato_in_fattura?()))
            Wx::message_box("Non e' possibile modificare la riga selezionata:\nSono presenti pagamenti di fatture collegate",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            return false
        end
        
        return true
      end
      
      def maxi_pagamento_compatibile?
        if(!self.maxi_pagamento.compatibile?(owner.owner.fattura_fornitore.nota_di_credito?))
          Wx::message_box("La tipologia di pagamento non e' compatibile con la banca.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          lku_tipo_pagamento.activate
          
          return false
        end
        
        # se all'incasso e' associato un tipo pagamento
        if(self.maxi_pagamento.tipo_pagamento)
          # che presuppone un movimento di banca
          if(self.maxi_pagamento.tipo_pagamento.movimento_di_banca?(owner.owner.fattura_fornitore.nota_di_credito?))
            # e l'incasso non ha una banca
            if(self.maxi_pagamento.banca.nil?) 
              # chiedo di inserire una banca
              Wx::message_box("La modalità di pagamento selezionata presuppone un movimento di banca:\nselezionare la banca se esiste, oppure, configurarne una nel pannello 'configurazione -> azienda'.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              lku_banca.activate

              return false
            end
          end
        end

        return true
      end
      
      def utilizzato_in_fattura?
        parent.result_set_lstrep_pagamenti_fattura.each do |pagamento_fattura|
          if((pagamento_fattura.instance_status != Helpers::BusinessClassHelper::ST_DELETE) && 
                (pagamento_fattura.instance_status != Helpers::BusinessClassHelper::ST_EMPTY))
            if(pagamento_fattura.maxi_pagamento_fornitore_id == self.selected)
              return true
            end
          end
        end

        return false
      end

      def categoria()
        Helpers::AnagraficaHelper::FORNITORI
      end

      def calcola_residui_pendenti()
        pagamenti_fattura = parent.result_set_lstrep_pagamenti_fattura
        self.result_set_lstrep_maxi_pagamenti.each do |maxi_pagamento|
          pagamenti_fattura.each do |pagamento_fattura|
            # se l'pagamento fattura e' stato cancellato o modificato
            if (pagamento_fattura.instance_status == Helpers::BusinessClassHelper::ST_DELETE) ||
                (pagamento_fattura.instance_status == Helpers::BusinessClassHelper::ST_UPDATE)
              # ma prima di essere cancellato/modificato e' stato cambiato
              if pagamento_fattura.maxi_pagamento_fornitore_id_changed?
                # controllo se il maxi pagamento era dello stesso tipo
                if pagamento_fattura.maxi_pagamento_fornitore_id_was == maxi_pagamento.id
                  maxi_pagamento.residuo += (pagamento_fattura.importo_changed? ? pagamento_fattura.importo_was : pagamento_fattura.importo)
                end
              else
                # se invece non e' stato cambiato prima di essere cancellato/modificato
                if pagamento_fattura.maxi_pagamento_fornitore_id == maxi_pagamento.id
                  # controllo se il maxi pagamento era dello stesso tipo
                  maxi_pagamento.residuo += (pagamento_fattura.importo_changed? ? pagamento_fattura.importo_was : pagamento_fattura.importo)
                end
              end
            elsif (pagamento_fattura.instance_status == Helpers::BusinessClassHelper::ST_INSERT)
              if pagamento_fattura.maxi_pagamento_fornitore_id == maxi_pagamento.id
                # controllo se il maxi pagamento era dello stesso tipo
                maxi_pagamento.residuo -= pagamento_fattura.importo
              end
            end
          end
        end
      end
      
      def reset_liste_collegate()
        lstrep_fatture_collegate.reset()
        self.result_set_lstrep_fatture_collegate = []
      end

      def collega_banca_al(tipo_pagamento)
        if(tipo_pagamento)
          # se alla modalita di pagamento e' associata una banca
          if(tipo_pagamento.banca)
            # visualizzo quella associata
            lku_banca.match_selection(tipo_pagamento.banca.codice) 
          else
            # se la modalita di pagamento movimenta la banca
            if tipo_pagamento.movimento_di_banca?
              # se esiste una banca predefinita
              if lku_banca.default
                # visualizzo quella predefinita
                lku_banca.set_default()
              else
                # nel caso ci siano piu' banche attive,
                banche_attive = lku_banca.select_all {|banca| banca.attiva?}
                # gli associo l'unica banca attiva disponibile
                if banche_attive.length == 1
                  lku_banca.view_data = banche_attive.first
                # altrimenti viene chiesto all'utente
                else
                  lku_banca.view_data = nil
                end
              end
            else
              # la banca non viene impostata
              lku_banca.view_data = nil
            end
          end
        else
          # senza modalita di pagamento non viene impostata la banca
          lku_banca.view_data = nil
        end
      end
      
      # aggiorna gli pagamenti della fattura ancora da salvare
#      def aggiorna_pagamenti_fattura_collegati()
#        parent.result_set_lstrep_pagamenti_fattura.each do |pagamento_fattura|
#          if((pagamento_fattura.instance_status == BusinessClassHelper::ST_INSERT) || (pagamento_fattura.instance_status == BusinessClassHelper::ST_UPDATE))
#            if(pagamento_fattura.maxi_pagamento_fornitore_id == maxi_pagamento.id)
#              pagamento_fattura.tipo_pagamento = maxi_pagamento.tipo_pagamento
#              pagamento_fattura.data_pagamento = maxi_pagamento.data_pagamento
#              pagamento_fattura.note = maxi_pagamento.note
#            end
#          end
#        end
#        
#        parent.lstrep_pagamenti_fattura.display(parent.result_set_lstrep_pagamenti_fattura)
#      end

    end
  end
end
