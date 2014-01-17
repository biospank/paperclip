# encoding: utf-8

module Views
  module Dialog
    class MaxiIncassiDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      WX_ID_F2 = Wx::ID_ANY

      attr_accessor :owner
      
      def initialize(parent)
        super()
        
        self.owner = parent
        
        model :maxi_pagamento_cliente => {:attrs => [:importo,
          :tipo_pagamento,
          :banca,
          :data_pagamento,
          :note],
          :alias => :maxi_incasso}
        
        controller :scadenzario

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "MAXI_INCASSI_DLG")

        xrc.find('txt_importo', self, :extends => DecimalField)
        xrc.find('lku_tipo_pagamento', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|tipo_pagamento| self.txt_descrizione_tipo_pagamento.view_data = (tipo_pagamento ? tipo_pagamento.descrizione : nil)},
                                :model => :tipo_pagamento,
                                :dialog => :tipi_pagamento_dialog,
                                :default => lambda {|tipo_pagamento| tipo_pagamento.predefinito?},
                                :view => Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
        end

        subscribe(:evt_tipo_pagamento_cliente_changed) do |data|
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
                                :folder => Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
        end
        
        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)
        xrc.find('txt_data_pagamento', self, :extends => DateField)
        xrc.find('txt_note', self, :extends => TextField)
        
        xrc.find('lstrep_maxi_incassi', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Tipo', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Banca', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Data', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Note', :width => 250, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Residuo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => :importo, :format => :currency},
            {:attr => lambda {|incasso| (incasso.tipo_pagamento ? incasso.tipo_pagamento.descrizione : '')}},
            {:attr => lambda {|incasso| (incasso.banca ? incasso.banca.descrizione : '')}},
            {:attr => :data_pagamento, :format => :date},
            {:attr => :note},
            {:attr => lambda {|incasso| (incasso.residuo)}, :format => :currency}
          ])
        end
        
        evt_menu(WX_ID_F2) do
          lstrep_maxi_incassi.activate()
        end

        evt_new do | evt |
          case evt.data[:subject]
          when :tipo_incasso
            end_modal(lku_tipo_pagamento.get_id)
          when :banca
            end_modal(lku_banca.get_id)
          end
        end

        xrc.find('lstrep_fatture_collegate', self, :extends => ReportField) do |list|
          list.column_info([{:caption => 'Cliente', :width => 400},
            {:caption => 'Fattura', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Data', :width => 120, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Importo', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Parziale', :width => 120, :align => Wx::LIST_FORMAT_RIGHT}
          ])
          list.data_info([{:attr => lambda {|incasso| incasso.fattura_cliente.cliente.denominazione}},
            {:attr => lambda {|incasso| incasso.fattura_cliente.num}},
            {:attr => lambda {|incasso| incasso.fattura_cliente.data_emissione}, :format => :date},
            {:attr => lambda {|incasso| incasso.fattura_cliente.importo}, :format => :currency},
            {:attr => lambda {|incasso| (incasso.importo)}, :format => :currency}
          ])
        end
        
        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)

        map_events(self)

        map_text_enter(self, {'txt_importo' => 'on_riga_text_enter',
                              'txt_data_pagamento' => 'on_riga_text_enter',
                              'lku_tipo_pagamento' => 'on_riga_text_enter',
                              'lku_banca' => 'on_riga_text_enter',
                              'txt_note' => 'on_riga_text_enter'})
                          
        lku_tipo_pagamento.load_data(ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::CLIENTI))
        
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
          display_maxi_incassi()        
          reset_gestione_riga()
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def reset_panel()
        begin
          reset_gestione_riga()
          
          lstrep_maxi_incassi.reset()
          self.result_set_lstrep_maxi_incassi = []
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
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_tipo_pagamento.view_data = ctrl.load_tipo_pagamento_cliente(dlg.selected)
              lku_tipo_pagamento_after_change()
            elsif answer == dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:tipo_incasso,
                [
                  Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW,
                  Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER
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
          if(lstrep_maxi_incassi.get_selected_item_count() > 0)
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
          transfer_maxi_incasso_from_view()
          if maxi_incasso_compatibile?
            if self.maxi_incasso.valid?
              Wx::BusyCursor.busy() do
                ctrl.save_maxi_incasso()
                display_maxi_incassi()
                lstrep_maxi_incassi.force_visible(:last)
                reset_gestione_riga()
                reset_liste_collegate()
                txt_importo.activate()
              end
            else
              Wx::message_box(self.maxi_incasso.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_maxi_incasso_error_field()

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
          transfer_maxi_incasso_from_view()
          if maxi_incasso_modificabile? and maxi_incasso_compatibile?
            if self.maxi_incasso.valid?
              Wx::BusyCursor.busy() do
                ctrl.save_maxi_incasso()
                display_maxi_incassi()
                reset_gestione_riga()
                reset_liste_collegate()
                txt_importo.activate()
              end
            else
              Wx::message_box(self.maxi_incasso.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              focus_maxi_incasso_error_field()

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
          if maxi_incasso_modificabile?
            transfer_maxi_incasso_from_view()
            Wx::BusyCursor.busy() do
              ctrl.delete_maxi_incasso()
              display_maxi_incassi()
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
          lstrep_maxi_incassi.display(self.result_set_lstrep_maxi_incassi)
          reset_liste_collegate()
          txt_importo.activate()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def lstrep_maxi_incassi_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_maxi_incassi.each do |record|
            if record.ident() == row_id
              self.maxi_incasso = record
              self.selected = self.maxi_incasso.id
              logger.debug("Selected: #{self.selected}")
              break
            end
          end
          transfer_maxi_incasso_to_view()
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

      def display_maxi_incassi()
        self.result_set_lstrep_maxi_incassi = ctrl.search_maxi_incassi()
        calcola_residui_pendenti()
        lstrep_maxi_incassi.display(self.result_set_lstrep_maxi_incassi)
      end
      
      def display_fatture_collegate()
        self.result_set_lstrep_fatture_collegate = self.maxi_incasso.pagamenti_fattura_cliente
        lstrep_fatture_collegate.display(self.result_set_lstrep_fatture_collegate, :ignore_focus => true)
      end
      
      def reset_gestione_riga()
        reset_maxi_incasso()
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

      def lstrep_maxi_incassi_item_activated(evt)
        on_confirm(evt)
      end

      def on_confirm(evt)
        if(lstrep_maxi_incassi.get_selected_item_count() == 0)
          Wx::message_box("Seleziona un incasso.",
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
      
      def maxi_incasso_modificabile?()
        if(((!self.maxi_incasso.pagamenti_fattura_cliente.blank?) or utilizzato_in_fattura?()))
            Wx::message_box("Non e' possibile modificare la riga selezionata:\nSono presenti incassi di fatture collegate",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
            return false
        end
        
        return true
      end
      
      def maxi_incasso_compatibile?
        if(!self.maxi_incasso.compatibile?(owner.owner.fattura_cliente.nota_di_credito?))
          Wx::message_box("La tipologia di incasso non e' compatibile con la banca.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          lku_tipo_pagamento.activate
          
          return false
        end
        
        # se all'incasso e' associato un tipo pagamento
        if(self.maxi_incasso.tipo_pagamento)
          # che presuppone un movimento di banca
          if(self.maxi_incasso.tipo_pagamento.movimento_di_banca?(owner.owner.fattura_cliente.nota_di_credito?))
            # e l'incasso non ha una banca
            if(self.maxi_incasso.banca.nil?) 
              # chiedo di inserire una banca
              Wx::message_box("La modalità di incasso selezionata presuppone un movimento di banca:\nselezionare la banca se esiste, oppure, configurarne una nel pannello 'configurazione -> azienda'.",
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
        parent.result_set_lstrep_incassi_fattura.each do |incasso_fattura|
          if((incasso_fattura.instance_status != Helpers::BusinessClassHelper::ST_DELETE) && 
                (incasso_fattura.instance_status != Helpers::BusinessClassHelper::ST_EMPTY))
            if(incasso_fattura.maxi_pagamento_cliente_id == self.selected)
              return true
            end
          end
        end

        return false
      end

      def categoria()
        Helpers::AnagraficaHelper::CLIENTI
      end

      def calcola_residui_pendenti()
        incassi_fattura = parent.result_set_lstrep_incassi_fattura
        self.result_set_lstrep_maxi_incassi.each do |maxi_incasso|
          incassi_fattura.each do |incasso_fattura|
            # se l'incasso fattura e' stato cancellato o modificato
            if (incasso_fattura.instance_status == Helpers::BusinessClassHelper::ST_DELETE) ||
                (incasso_fattura.instance_status == Helpers::BusinessClassHelper::ST_UPDATE)
              # ma prima di essere cancellato/modificato e' stato cambiato
              if incasso_fattura.maxi_pagamento_cliente_id_changed?
                # controllo se il maxi incasso era dello stesso tipo
                if incasso_fattura.maxi_pagamento_cliente_id_was == maxi_incasso.id
                  maxi_incasso.residuo += (incasso_fattura.importo_changed? ? incasso_fattura.importo_was : incasso_fattura.importo)
                end
              else
                # se invece non e' stato cambiato prima di essere cancellato/modificato
                if incasso_fattura.maxi_pagamento_cliente_id == maxi_incasso.id
                  # controllo se il maxi incasso era dello stesso tipo
                  maxi_incasso.residuo += (incasso_fattura.importo_changed? ? incasso_fattura.importo_was : incasso_fattura.importo)
                end
              end
            elsif (incasso_fattura.instance_status == Helpers::BusinessClassHelper::ST_INSERT)
              if incasso_fattura.maxi_pagamento_cliente_id == maxi_incasso.id
                # controllo se il maxi incasso era dello stesso tipo
                maxi_incasso.residuo -= incasso_fattura.importo
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
      
      # aggiorna gli incassi della fattura ancora da salvare
#      def aggiorna_incassi_fattura_collegati()
#        parent.result_set_lstrep_incassi_fattura.each do |incasso_fattura|
#          if((incasso_fattura.instance_status == BusinessClassHelper::ST_INSERT) || (incasso_fattura.instance_status == BusinessClassHelper::ST_UPDATE))
#            if(incasso_fattura.maxi_pagamento_cliente_id == maxi_incasso.id)
#              incasso_fattura.tipo_pagamento = maxi_incasso.tipo_pagamento
#              incasso_fattura.data_pagamento = maxi_incasso.data_pagamento
#              incasso_fattura.note = maxi_incasso.note
#            end
#          end
#        end
#        
#        parent.lstrep_incassi_fattura.display(parent.result_set_lstrep_incassi_fattura)
#      end

    end
  end
end
