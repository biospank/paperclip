# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'

module Views
  module Fatturazione
    module NSRigheFatturaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :riepilogo_importi, :importi_solo_iva, :totale_imponibile,
                    :totale_iva, :totale_nota_spese, :totale_ritenuta
      
      def ui
        
        controller :fatturazione

        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('chk_importo_iva', self, :extends => CheckField)
        xrc.find('txt_descrizione', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_descrizione_keypress(evt) }
        end
        xrc.find('txt_importo', self, :extends => DecimalField)
        xrc.find('lku_aliquota', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|aliquota| self.txt_descrizione_aliquota.view_data = (aliquota ? aliquota.descrizione : nil)},
                                :model => :aliquota,
                                :dialog => :aliquote_dialog,
                                :default => lambda {|aliquota| aliquota.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_NOTA_SPESE_FOLDER)
        end
                              
        subscribe(:evt_aliquota_changed) do |data|
          lku_aliquota.load_data(data)
        end

        xrc.find('txt_descrizione_aliquota', self, :extends => TextField)

        xrc.find('lstrep_righe_nota_spese', self, :extends => EditableReportField)
        xrc.find('lstrep_iva_ritenute', self, :extends => ReportField)

        xrc.find('lbl_importo_riga', self)

        xrc.find('lbl_imponibile', self)
        xrc.find('lbl_iva', self)
        xrc.find('lbl_totale', self)
        xrc.find('cpt_ritenuta', self)
        xrc.find('lbl_ritenuta', self)
        xrc.find('cpt_netto', self)
        xrc.find('lbl_netto', self)
        
        xrc.find('btn_incassi_ricorrenti', self)
        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        width = (configatron.screen.width <= 1024 ? 100 : 150)

        lstrep_iva_ritenute.column_info([{:caption => 'Aliquota', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Imponibile', :width => width, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Iva', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Ritenuta', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
          ])
        lstrep_iva_ritenute.data_info([{:attr => :aliquota, :format => :percentage},
            {:attr => :imponibile, :format => :currency},
            {:attr => :iva, :format => :currency},
            {:attr => :ritenuta, :format => :currency}])

        map_events(self)
        map_text_enter(self, {'chk_importo_iva' => 'on_riga_text_enter', 
                              'txt_descrizione' => 'on_riga_text_enter', 
                              'txt_importo' => 'on_riga_text_enter'})
                          
        map_text_enter(self, {'lku_aliquota' => 'on_match_riga_text_enter'})
        
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
          
          lstrep_righe_nota_spese.reset()
          self.result_set_lstrep_righe_nota_spese = []
          lstrep_iva_ritenute.reset()
          self.result_set_lstrep_iva_ritenute = []
          
          riepilogo_nota_spese()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      def chk_importo_iva_click(evt)
        update_riga_ui()
      end

      def lku_aliquota_enter(evt)
        begin
          lku_aliquota.match_selection()
          on_riga_text_enter(evt)
        rescue Exception => e
          log_error(self, e)
        end
      end
      
      def on_riga_text_enter(evt)
        begin
          if(lstrep_righe_nota_spese.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      # necessario in modifica
      def on_match_riga_text_enter(evt)
        begin
          evt.get_event_object().match_selection()
          if(lstrep_righe_nota_spese.get_selected_item_count() > 0)
            btn_modifica_click(evt)
          else
            btn_aggiungi_click(evt)
          end
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_incassi_ricorrenti_click(evt)
        begin
          if cliente?
            transfer_riga_nota_spese_from_view()
            incassi_ricorrenti_dlg = Views::Dialog::IncassiRicorrentiDialog.new(owner, false)
            incassi_ricorrenti_dlg.center_on_screen(Wx::BOTH)
            answer = incassi_ricorrenti_dlg.show_modal()
            if answer == Wx::ID_OK
              incasso_ricorrente = ctrl.load_incasso_ricorrente(incassi_ricorrenti_dlg.selected)
              self.riga_nota_spese.descrizione = incasso_ricorrente.descrizione
              self.riga_nota_spese.importo = incasso_ricorrente.importo
              transfer_riga_nota_spese_to_view()
              txt_descrizione.activate()
            elsif answer == incassi_ricorrenti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:incasso_ricorrente, 
                [
                  Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                  Helpers::FatturazioneHelper::WXBRA_NOTA_SPESE_FOLDER
                ]
              )
              # This sends the event for processing by listeners
              process_event(evt_new)
            else
              logger.debug("You pressed Cancel")
            end

            incassi_ricorrenti_dlg.destroy()
            
          end          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_aggiungi_click(evt)
        begin
          if cliente?
            transfer_riga_nota_spese_from_view()
            if self.riga_nota_spese.valid?
              self.result_set_lstrep_righe_nota_spese << self.riga_nota_spese
              lstrep_righe_nota_spese.display(self.result_set_lstrep_righe_nota_spese)
              lstrep_righe_nota_spese.force_visible(:last)
              riepilogo_nota_spese()
              reset_gestione_riga()
              txt_descrizione.activate()
            else
              Wx::message_box(self.riga_nota_spese.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              
              focus_riga_nota_spese_error_field()

            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_modifica_click(evt)
        begin
          if cliente?
            transfer_riga_nota_spese_from_view()
            if self.riga_nota_spese.valid?
              self.riga_nota_spese.log_attr()
              lstrep_righe_nota_spese.display(self.result_set_lstrep_righe_nota_spese)
              riepilogo_nota_spese()
              reset_gestione_riga()
              txt_descrizione.activate()
            else
              Wx::message_box(self.riga_nota_spese.error_msg,
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
              
              focus_riga_nota_spese_error_field()

            end
          end          
        rescue Exception => e
          log_error(self, e)
        end

      end
      
      def btn_elimina_click(evt)
        begin
          if cliente?
            self.riga_nota_spese.log_attr(Helpers::BusinessClassHelper::ST_DELETE)
            lstrep_righe_nota_spese.display(self.result_set_lstrep_righe_nota_spese)
            riepilogo_nota_spese()
            reset_gestione_riga()
            txt_descrizione.activate()
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
            # serve ad eliminare l'eventuale focus dalla lista
            # evita che rimanga selezionato un elemento della lista
            lstrep_righe_nota_spese.display(self.result_set_lstrep_righe_nota_spese)
            txt_descrizione.activate()
          end          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def lstrep_righe_nota_spese_item_selected(evt)
        begin
          row_id = evt.get_item().get_data()
          self.result_set_lstrep_righe_nota_spese.each do |record|
            if record.ident() == row_id
              self.riga_nota_spese = record
              break
            end
          end
          transfer_riga_nota_spese_to_view()
          update_riga_ui()
          enable_widgets [btn_modifica, btn_elimina, btn_nuovo]
          disable_widgets [btn_aggiungi]
          #txt_descrizione.activate()
        rescue Exception => e
          log_error(e)
        end

        evt.skip(false)
      end

      def lstrep_righe_nota_spese_item_activated(evt)
        txt_descrizione.activate()
      end

      def display_righe_nota_spese(nota_spese)
        self.result_set_lstrep_righe_nota_spese = ctrl.search_righe_nota_spese(nota_spese)
        lstrep_righe_nota_spese.display(self.result_set_lstrep_righe_nota_spese)
        reset_gestione_riga()
      end
      
      def cliente?
        return owner.cliente?
      end

      def reset_gestione_riga()
        reset_riga_nota_spese()
        lku_aliquota.set_default()
        update_riga_ui()
        enable_widgets [btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
      end
      
      def changed?
        self.result_set_lstrep_righe_nota_spese.detect { |riga| riga.touched? }
      end
    end

    module NSRigheFatturaCommercioPanel
      include Views::Fatturazione::NSRigheFatturaPanel
      
      def ui

        super
        
        logger.debug('initializing NSRigheFatturaCommercioPanel...')

        model :riga_nota_spese_commercio => {:attrs => [:importo_iva,
          :descrizione,
          :qta,
          :importo,
          :aliquota],
          :alias => :riga_nota_spese}
        
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_qta', self, :extends => NumericField)

        width = (configatron.screen.width <= 1024 ? 500 : 750)
        
        lstrep_righe_nota_spese.column_info([{:caption => 'Descrizione', :width => width},
            {:caption => 'Quantità', :width => 100, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Descrizione Iva', :width => 150},
          ])
        lstrep_righe_nota_spese.data_info([{:attr => :descrizione},
            {:attr => :qta,
              :if => Proc.new {|rns| (rns.qta > 0) and (!rns.importo_iva?)}
            },
            {:attr => :importo, 
              :format => :currency,
              :if => lambda {|rns| rns.importo != 0}
            },
            {:attr => lambda {|rns| rns.aliquota.descrizione },
              :if => Proc.new {|rns| !rns.importo_iva?}
            }
          ])

        map_text_enter(self, {'txt_qta' => 'on_riga_text_enter'})
                          
      end
     
      def txt_descrizione_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              owner.txt_data_emissione.activate() 
            else
              txt_qta.activate() 
            end
          when Wx::K_F5
            btn_incassi_ricorrenti_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def update_riga_ui()
        if chk_importo_iva.checked?
          disable_widgets [txt_qta, lku_aliquota]
          lbl_importo_riga.label = 'Importo:'
        else
          enable_widgets [txt_qta, lku_aliquota]
          lbl_importo_riga.label = 'Prezzo Unit.:'
        end
      end
      
      def riepilogo_nota_spese()    
        self.totale_imponibile = 0.0
        self.totale_iva = 0.0
        self.totale_nota_spese = 0.0
        self.totale_ritenuta = 0.0

        self.riepilogo_importi = {}
        self.importi_solo_iva = 0.0

        self.result_set_lstrep_righe_nota_spese.each do |riga|
          if riga.valid_record?
            if riga.importo_iva?
              self.importi_solo_iva += riga.importo
            else
              importo = (riepilogo_importi[riga.aliquota_id] || 0.0)
              riepilogo_importi[riga.aliquota_id] = (importo + ((riga.qta.zero?) ? riga.importo : (riga.importo * riga.qta)))
            end
          end
        end

        data_matrix = []

        riepilogo_importi.each_pair do |aliquota_id, imponibile_iva|
          data = []
          data << lku_aliquota.instance_hash[aliquota_id].percentuale
          data << imponibile_iva
          data << ((imponibile_iva * lku_aliquota.instance_hash[aliquota_id].percentuale) / 100)

          data_matrix << data

          self.totale_imponibile += imponibile_iva
          self.totale_iva += ((imponibile_iva * lku_aliquota.instance_hash[aliquota_id].percentuale) / 100)

        end

        self.totale_iva += importi_solo_iva

        self.totale_nota_spese = self.totale_imponibile + self.totale_iva

        ritenuta = owner.nota_spese.ritenuta
        if ritenuta
          self.totale_ritenuta = ((self.totale_imponibile * ritenuta.percentuale) / 100)
          data = []
          data << ritenuta.percentuale
          data << self.totale_imponibile
          data << ''
          data << self.totale_ritenuta
          
          data_matrix << data
        end    
    
        lstrep_iva_ritenute.display_matrix(data_matrix)
        
        lbl_imponibile.label = Helpers::ApplicationHelper.currency(self.totale_imponibile)
        lbl_iva.label = Helpers::ApplicationHelper.currency(self.totale_iva)
        lbl_totale.label = Helpers::ApplicationHelper.currency(self.totale_nota_spese)

        if ritenuta
          cpt_ritenuta.show()
          lbl_ritenuta.label = Helpers::ApplicationHelper.currency(self.totale_ritenuta)
          cpt_netto.show()
          lbl_netto.label = Helpers::ApplicationHelper.currency((self.totale_nota_spese - self.totale_ritenuta))
        else
          cpt_ritenuta.hide()
          lbl_ritenuta.label = ''
          cpt_netto.hide()
          lbl_netto.label = ''
        end

        # VERIFICARE CHE L'IMPORTO DELLA NOTA SPESE SIA SALVATO CORRETTAMENTE
        #        parent.ns_fattura_panel.nota_spese.importo = eval(Helpers::ApplicationHelper.number(self.totale_nota_spese))
        owner.nota_spese.imponibile = self.totale_imponibile
        owner.nota_spese.iva = self.totale_iva
        owner.nota_spese.importo = self.totale_nota_spese

      end

    end

    module NSRigheFatturaServiziPanel
      include Views::Fatturazione::NSRigheFatturaPanel

      def ui

        super

        logger.debug('initializing NSRigheFatturaServiziPanel...')

        model :riga_nota_spese_servizi => {:attrs => [:importo_iva,
          :descrizione,
          :importo,
          :aliquota],
          :alias => :riga_nota_spese}
        
        controller :fatturazione

        width = (configatron.screen.width <= 1024 ? 600 : 850)

        lstrep_righe_nota_spese.column_info([{:caption => 'Descrizione', :width => 850},
            {:caption => 'Importo', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Descrizione Iva', :width => 150},
          ])
        lstrep_righe_nota_spese.data_info([{:attr => :descrizione},
            {:attr => :importo, 
              :format => :currency,
              :if => lambda {|rns| rns.importo != 0}
            },
            {:attr => lambda {|rns| rns.aliquota.descrizione },
              :if => Proc.new {|rns| !rns.importo_iva?}
            }
          ])

      end
     
      def txt_descrizione_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              owner.txt_data_emissione.activate() 
            else
              txt_importo.activate() 
            end
          when Wx::K_F5
            btn_incassi_ricorrenti_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def update_riga_ui()
        if chk_importo_iva.checked?
          disable_widgets [lku_aliquota]
        else
          enable_widgets [lku_aliquota]
        end
      end
      
      def riepilogo_nota_spese()    
        self.totale_imponibile = 0.0
        self.totale_iva = 0.0
        self.totale_nota_spese = 0.0
        self.totale_ritenuta = 0.0

        self.riepilogo_importi = {}
        self.importi_solo_iva = 0.0

        self.result_set_lstrep_righe_nota_spese.each do |riga|
          if riga.valid_record?
            if riga.importo_iva?
              self.importi_solo_iva += riga.importo
            else
              importo = (riepilogo_importi[riga.aliquota_id] || 0.0)
              riepilogo_importi[riga.aliquota_id] = (importo + riga.importo)
            end
          end
        end

        data_matrix = []

        riepilogo_importi.each_pair do |aliquota_id, imponibile_iva|
          data = []
          data << lku_aliquota.instance_hash[aliquota_id].percentuale
          data << imponibile_iva
          data << ((imponibile_iva * lku_aliquota.instance_hash[aliquota_id].percentuale) / 100)

          data_matrix << data

          self.totale_imponibile += imponibile_iva
          self.totale_iva += ((imponibile_iva * lku_aliquota.instance_hash[aliquota_id].percentuale) / 100)

        end

        lstrep_iva_ritenute.display_matrix(data_matrix)
        
        self.totale_iva += importi_solo_iva

        self.totale_nota_spese = self.totale_imponibile + self.totale_iva

        ritenuta = owner.nota_spese.ritenuta

        if ritenuta
          self.totale_ritenuta = ((self.totale_imponibile * ritenuta.percentuale) / 100)
          data = []
          data << ritenuta.percentuale
          data << self.totale_imponibile
          data << ''
          data << self.totale_ritenuta
          
          data_matrix << data
          
        end    
    
        lstrep_iva_ritenute.display_matrix(data_matrix)
        
        lbl_imponibile.label = Helpers::ApplicationHelper.currency(self.totale_imponibile)
        lbl_iva.label = Helpers::ApplicationHelper.currency(self.totale_iva)
        lbl_totale.label = Helpers::ApplicationHelper.currency(self.totale_nota_spese)

        if ritenuta
          cpt_ritenuta.show()
          lbl_ritenuta.label = Helpers::ApplicationHelper.currency(self.totale_ritenuta)
          cpt_netto.show()
          lbl_netto.label = Helpers::ApplicationHelper.currency((self.totale_nota_spese - self.totale_ritenuta))
        else
          cpt_ritenuta.hide()
          lbl_ritenuta.label = ''
          cpt_netto.hide()
          lbl_netto.label = ''
        end

        # VERIFICARE CHE L'IMPORTO DELLA NOTA SPESE SIA SALVATO CORRETTAMENTE
        #        parent.ns_fattura_panel.nota_spese.importo = eval(Helpers::ApplicationHelper.number(self.totale_nota_spese))
        owner.nota_spese.imponibile = self.totale_imponibile
        owner.nota_spese.iva = self.totale_iva
        owner.nota_spese.importo = self.totale_nota_spese

      end

    end
    
  end
end