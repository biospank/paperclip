# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'

module Views
  module Fatturazione
    module NSRigheFatturaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :riepilogo_importi, :importi_solo_iva
      
      def ui
        @riepilogo_importi = {}
        @importi_solo_iva = 0.0
        
        controller :fatturazione

        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('chk_importo_iva', self, :extends => CheckField)
        xrc.find('txt_descrizione', self, :extends => TextField)
        xrc.find('txt_importo', self, :extends => DecimalField)
        xrc.find('cmb_aliquota', self, :extends => ComboObjectField)
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
        
        xrc.find('btn_aggiungi', self)
        xrc.find('btn_modifica', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        lstrep_iva_ritenute.column_info([{:caption => 'Aliquota', :width => 100, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Imponibile', :width => 150, :align => Wx::LIST_FORMAT_RIGHT},
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
                          
        # carico le aliquote attive
        cmb_aliquota.load_data(ctrl.search_aliquote(), 
          :label => :codice, 
          :select => :first, 
          :if => lambda {|aliquota| aliquota.attiva? })

#        evt_aliquota_changed { | evt | cmb_aliquota.load_data(evt.result_set, :label => :codice, :select => :first) }        

      end

      def reset_panel()
        begin
          reset_gestione_riga()
          
#          # carico le aliquote attive
#          cmb_aliquota.load_data(ctrl.search_aliquote_attive(), :label => :codice, :select => :first)

          cmb_aliquota.select_first()
          
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

      def cmb_aliquota_enter(evt)
        begin
          cmb_aliquota.match_selection()
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
      
      def btn_aggiungi_click(evt)
        begin
          if cliente?
            transfer_riga_nota_spese_from_view()
            if self.riga_nota_spese.valid?
              self.result_set_lstrep_righe_nota_spese << self.riga_nota_spese
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

      def display_righe_nota_spese(nota_spese)
        self.result_set_lstrep_righe_nota_spese = ctrl.search_righe_nota_spese(nota_spese)
        lstrep_righe_nota_spese.display(self.result_set_lstrep_righe_nota_spese)
        reset_gestione_riga()
        riepilogo_nota_spese()
      end
      
      def cliente?
        return owner.cliente?
      end

      def reset_gestione_riga()
        reset_riga_nota_spese()
        cmb_aliquota.select_first()
        update_riga_ui()
        enable_widgets [btn_aggiungi, btn_nuovo]
        disable_widgets [btn_modifica, btn_elimina]
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

        lstrep_righe_nota_spese.column_info([{:caption => 'Descrizione', :width => 750},
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
     
      def update_riga_ui()
        if chk_importo_iva.checked?
          disable_widgets [txt_qta, cmb_aliquota]
          lbl_importo_riga.label = 'Importo:'
        else
          enable_widgets [txt_qta, cmb_aliquota]
          lbl_importo_riga.label = 'Prezzo Unit.:'
        end
      end
      
      def riepilogo_nota_spese()    
        totale_imponibile = 0.0
        totale_iva = 0.0
        totale_nota_spese = 0.0
        totale_ritenuta = 0.0

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
          data << cmb_aliquota.instance_hash[aliquota_id].percentuale
          data << imponibile_iva
          data << ((imponibile_iva * cmb_aliquota.instance_hash[aliquota_id].percentuale) / 100)

          data_matrix << data

          totale_imponibile += imponibile_iva
          totale_iva += ((imponibile_iva * cmb_aliquota.instance_hash[aliquota_id].percentuale) / 100)

        end

        totale_iva += importi_solo_iva

        totale_nota_spese = totale_imponibile + totale_iva

        ritenuta = owner.nota_spese.ritenuta
        if ritenuta
          totale_ritenuta = ((totale_imponibile * ritenuta.percentuale) / 100)
          data = []
          data << Helpers::ApplicationHelper.percentage(ritenuta.percentuale)
          data << Helpers::ApplicationHelper.currency(totale_imponibile)
          data << ''
          data << Helpers::ApplicationHelper.currency(totale_ritenuta)
          
          data_matrix << data
          
        end    
    
        lstrep_iva_ritenute.display_matrix(data_matrix)
        
        lbl_imponibile.label = Helpers::ApplicationHelper.currency(totale_imponibile)
        lbl_iva.label = Helpers::ApplicationHelper.currency(totale_iva)
        lbl_totale.label = Helpers::ApplicationHelper.currency(totale_nota_spese)

        if ritenuta
          cpt_ritenuta.show()
          lbl_ritenuta.label = Helpers::ApplicationHelper.currency(totale_ritenuta)
          cpt_netto.show()
          lbl_netto.label = Helpers::ApplicationHelper.currency((totale_nota_spese - totale_ritenuta))
        else
          cpt_ritenuta.hide()
          lbl_ritenuta.label = ''
          cpt_netto.hide()
          lbl_netto.label = ''
        end

        # VERIFICARE CHE L'IMPORTO DELLA NOTA SPESE SIA SALVATO CORRETTAMENTE
        #        parent.ns_fattura_panel.nota_spese.importo = eval(Helpers::ApplicationHelper.number(totale_nota_spese))
        owner.nota_spese.importo = totale_nota_spese

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
     
      def update_riga_ui()
        if chk_importo_iva.checked?
          disable_widgets [cmb_aliquota]
        else
          enable_widgets [cmb_aliquota]
        end
      end
      
      def riepilogo_nota_spese()    
        totale_imponibile = 0.0
        totale_iva = 0.0
        totale_nota_spese = 0.0
        totale_ritenuta = 0.0

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
          data << cmb_aliquota.instance_hash[aliquota_id].percentuale
          data << imponibile_iva
          data << ((imponibile_iva * cmb_aliquota.instance_hash[aliquota_id].percentuale) / 100)

          data_matrix << data

          totale_imponibile += imponibile_iva
          totale_iva += ((imponibile_iva * cmb_aliquota.instance_hash[aliquota_id].percentuale) / 100)

        end

        lstrep_iva_ritenute.display_matrix(data_matrix)
        
        totale_iva += importi_solo_iva

        totale_nota_spese = totale_imponibile + totale_iva

        ritenuta = owner.nota_spese.ritenuta

        if ritenuta
          totale_ritenuta = ((totale_imponibile * ritenuta.percentuale) / 100)
          data = []
          data << ritenuta.percentuale
          data << totale_imponibile
          data << ''
          data << totale_ritenuta
          
          data_matrix << data
          
        end    
    
        lstrep_iva_ritenute.display_matrix(data_matrix)
        
        lbl_imponibile.label = Helpers::ApplicationHelper.currency(totale_imponibile)
        lbl_iva.label = Helpers::ApplicationHelper.currency(totale_iva)
        lbl_totale.label = Helpers::ApplicationHelper.currency(totale_nota_spese)

        if ritenuta
          cpt_ritenuta.show()
          lbl_ritenuta.label = Helpers::ApplicationHelper.currency(totale_ritenuta)
          cpt_netto.show()
          lbl_netto.label = Helpers::ApplicationHelper.currency((totale_nota_spese - totale_ritenuta))
        else
          cpt_ritenuta.hide()
          lbl_ritenuta.label = ''
          cpt_netto.hide()
          lbl_netto.label = ''
        end

        # VERIFICARE CHE L'IMPORTO DELLA NOTA SPESE SIA SALVATO CORRETTAMENTE
        #        parent.ns_fattura_panel.nota_spese.importo = eval(Helpers::ApplicationHelper.number(totale_nota_spese))
        owner.nota_spese.importo = totale_nota_spese

      end

    end
    
  end
end