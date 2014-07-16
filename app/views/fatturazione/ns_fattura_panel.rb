# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/nota_spese_dialog'
require 'app/views/fatturazione/ns_righe_fattura_panel'

module Views
  module Fatturazione
    module NSFatturaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog
      
      def ui(container=nil)

        model :cliente => {:attrs => [:denominazione, :p_iva]},
          :nota_spese => {:attrs => [:num, :data_emissione, :ritenuta]}
        
        controller :fatturazione

        logger.debug('initializing NSFatturaPanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_ns_changed) do |data|
          chce_anno.load_data(data, :select => :last)
        end

        xrc.find('txt_num', self, :extends => TextField) do |field|
          field.evt_char { |evt| txt_num_keypress(evt) }
        end
        xrc.find('txt_data_emissione', self, :extends => DateField) do |field|
          field.move_after_in_tab_order(txt_num)
          field.evt_char { |evt| txt_data_emissione_keypress(evt) }
        end
        xrc.find('chk_ritenuta_flag', self, :extends => FkCheckField)
        xrc.find('lku_ritenuta', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|ritenuta| self.txt_descrizione_ritenuta.view_data = (ritenuta ? ritenuta.descrizione : nil)},
                                :model => :ritenuta,
                                :dialog => :ritenute_dialog,
                                :default => lambda {|ritenuta| ritenuta.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                                :folder => Helpers::FatturazioneHelper::WXBRA_NOTA_SPESE_FOLDER)
        end
        
        subscribe(:evt_ritenuta_changed) do |data|
          lku_ritenuta.load_data(data)
        end

        subscribe(:evt_stampa_documenti) do |docs|
          stampa_documenti(docs)
        end

        subscribe(:evt_dettaglio_nota_spese) do |nota_spese|
          self.nota_spese = nota_spese
          self.cliente = self.nota_spese.cliente
          transfer_cliente_to_view()
          transfer_nota_spese_to_view()
          chce_anno.view_data = self.nota_spese.data_emissione.to_s(:year)

          ns_righe_fattura_panel.display_righe_nota_spese(self.nota_spese)
          ns_righe_fattura_panel.riepilogo_nota_spese()

          disable_widgets [
            txt_num,
            chce_anno,
            txt_data_emissione,
            chk_ritenuta_flag,
            lku_ritenuta
          ]

          if nota_spese.fatturata?
            Wx::message_box("#{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} non modificabile.",
              'Avvertenza',
              Wx::OK | Wx::ICON_WARNING, self)
          end

          reset_nota_spese_command_state()
          ns_righe_fattura_panel.txt_descrizione.activate()

        end
        
        xrc.find('txt_descrizione_ritenuta', self, :extends => TextField)

        xrc.find('btn_cliente', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_stampa', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)

        map_events(self)
        
        case configatron.attivita
        when Models::Azienda::ATTIVITA[:commercio]
          xrc.find('NS_RIGHE_FATTURA_SERVIZI_PANEL', container, 
            :force_parent => self)
          
          ns_righe_fattura_servizi_panel.hide()
          
          xrc.find('NS_RIGHE_FATTURA_COMMERCIO_PANEL', container, 
            :extends => Views::Fatturazione::NSRigheFatturaCommercioPanel, 
            :force_parent => self,
            :alias => :ns_righe_fattura_panel)
          
          ns_righe_fattura_commercio_panel.show()
          
          
        when Models::Azienda::ATTIVITA[:servizi]
          xrc.find('NS_RIGHE_FATTURA_COMMERCIO_PANEL', container, 
            :force_parent => self)
          
          ns_righe_fattura_commercio_panel.hide()

          xrc.find('NS_RIGHE_FATTURA_SERVIZI_PANEL', container, 
            :extends => Views::Fatturazione::NSRigheFatturaServiziPanel, 
            :force_parent => self,
            :alias => :ns_righe_fattura_panel)
          
          ns_righe_fattura_servizi_panel.show()
         
        end

        ns_righe_fattura_panel.ui()
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      # inizializza il numero fattura
      # e gli anni contabili se non sono gia presenti
      def init_panel()
        # calcolo il progressivo
        txt_num.view_data = Models::ProgressivoNotaSpese.next_sequence(chce_anno.string_selection()) if txt_num.view_data.blank?
        # imposto la data di oggi
        txt_data_emissione.view_data = Date.today if txt_data_emissione.view_data.blank?
        
        reset_nota_spese_command_state()

        ns_righe_fattura_panel.init_panel()
        
        txt_num.enabled? ? txt_num.activate() : ns_righe_fattura_panel.txt_descrizione.activate()
      end
      
      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_cliente()
          reset_nota_spese()
          
          # carico gli anni contabili
          chce_anno.load_data(ctrl.load_anni_contabili(nota_spese.class), :select => :last) if chce_anno.empty?
        
          chce_anno.select_last()

          # calcolo il progressivo
          txt_num.view_data = Models::ProgressivoNotaSpese.next_sequence(chce_anno.string_selection())

          # imposto la data di oggi
          txt_data_emissione.view_data = Date.today

          chk_ritenuta_flag.view_data = nil

          enable_widgets [
            txt_num,
            chce_anno,
            txt_data_emissione,
            chk_ritenuta_flag
          ]

          disable_widgets [
            lku_ritenuta
          ]

          reset_nota_spese_command_state()

          ns_righe_fattura_panel.reset_panel()

          txt_num.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def txt_num_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_F5
            btn_cliente_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_data_emissione_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              txt_num.activate()
            else
              ns_righe_fattura_panel.txt_descrizione.activate()
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_cliente_click(evt)
        begin
          Wx::BusyCursor.busy() do
            clienti_dlg = Views::Dialog::ClientiDialog.new(self)
            clienti_dlg.center_on_screen(Wx::BOTH)
            answer = clienti_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_panel()
              self.cliente = ctrl.load_cliente(clienti_dlg.selected)
              self.nota_spese.cliente = self.cliente
              transfer_cliente_to_view()
              txt_data_emissione.activate()
            elsif answer == clienti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:cliente,
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

            clienti_dlg.destroy()
          end

        rescue Exception => e
          log_error(self, e)
        end
        
        evt.skip()
      end

      def chce_anno_select(evt)
        begin
          anno = evt.get_event_object().view_data()
          if anno.eql? Date.today.year.to_s
            txt_data_emissione.view_data = nota_spese.data_emissione
          else
            txt_data_emissione.view_data = Date.new(anno.to_i).end_of_year()
          end
          txt_num.view_data = Models::ProgressivoNotaSpese.next_sequence(anno)
        
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_variazione_click(evt)
        begin
          Wx::BusyCursor.busy() do
            # se esiste ricerca solo le occorrenze associate ad un cliente
            transfer_cliente_from_view()
            self.dialog_sql_criteria = self.nota_spese_sql_criteria()
            nota_spese_dlg = Views::Dialog::NotaSpeseDialog.new(self)
            nota_spese_dlg.center_on_screen(Wx::BOTH)
            if nota_spese_dlg.show_modal() == Wx::ID_OK
              self.nota_spese = ctrl.load_nota_spese(nota_spese_dlg.selected)
              self.cliente = self.nota_spese.cliente
              transfer_cliente_to_view()
              transfer_nota_spese_to_view()
              chce_anno.view_data = self.nota_spese.data_emissione.to_s(:year)
              chk_ritenuta_flag.view_data = self.nota_spese.ritenuta
              ns_righe_fattura_panel.display_righe_nota_spese(self.nota_spese)
              ns_righe_fattura_panel.riepilogo_nota_spese()

              disable_widgets [
                txt_num,
                chce_anno,
                txt_data_emissione,
                chk_ritenuta_flag,
                lku_ritenuta
              ]

              if nota_spese.fatturata?
                Wx::message_box("#{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} non modificabile.",
                  'Avvertenza',
                  Wx::OK | Wx::ICON_WARNING, self)
              end

              reset_nota_spese_command_state()
              ns_righe_fattura_panel.txt_descrizione.activate()

            else
              logger.debug("You pressed Cancel")
            end

            nota_spese_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_stampa_click(evt)
        begin
          stampa_nota_spese()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
        
      end
      
      def chk_ritenuta_flag_click(evt)
        begin
          if chk_ritenuta_flag.checked?
            enable_widgets [lku_ritenuta]
            lku_ritenuta.set_default()
            lku_ritenuta.activate()
            transfer_nota_spese_from_view()
            ns_righe_fattura_panel.riepilogo_nota_spese()
          else
            disable_widgets [lku_ritenuta]
            lku_ritenuta.view_data = nil
            transfer_nota_spese_from_view()
            ns_righe_fattura_panel.riepilogo_nota_spese()
          end

        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_ritenuta_after_change()
        begin
          lku_ritenuta.match_selection()
          transfer_nota_spese_from_view()
          ns_righe_fattura_panel.riepilogo_nota_spese()
        rescue Exception => e
          log_error(self, e)
        end
        
      end
      
      def btn_salva_click(evt)
        begin
          # per controllare il tasto funzione F8 associato al salva
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                  transfer_nota_spese_from_view()
                  if cliente? and check_ritenuta()
                    unless nota_spese.num.strip.match(/^[0-9]*$/)
                      res = Wx::message_box("La documento che si sta salvando non segue la numerazione standard:\nnon verra' fatto alcun controllo sulla validita'.\nProcedo con il savataggio dei dati?",
                        'Avvertenza',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res == Wx::YES
                        return
                      end
                    end

                    if self.nota_spese.valid?
                      ctrl.save_nota_spese()

                      notify(:evt_nota_spese_changed)
                      # carico gli anni contabili dei progressivi nota spese
                      progressivi_ns = ctrl.load_anni_contabili_progressivi(Models::ProgressivoNotaSpese)
                      notify(:evt_progressivo_ns, progressivi_ns)

                      Wx::message_box('Salvataggio avvenuto correttamente',
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      res_stampa = Wx::message_box("Vuoi stampare il documento?",
                        'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res_stampa == Wx::YES
                        stampa_nota_spese()
                      end

                      reset_panel()
                    else
                      Wx::message_box(self.nota_spese.error_msg,
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      focus_nota_spese_error_field()

                    end
                  end
                else
                  Wx::message_box('Utente non autorizzato.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
              else
                Wx::message_box("Licenza scaduta il #{ctrl.licenza.get_data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            end
          end
        rescue ActiveRecord::StaleObjectError
          Wx::message_box("Il documento e' stato modificato da un processo esterno.\nRicaricare i dati aggiornati prima del salvataggio.",
            'ATTENZIONE!!',
            Wx::OK | Wx::ICON_WARNING, self)
          
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if ctrl.licenza.attiva?
              if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                if nota_spese.fatturata?
                  Wx::message_box("#{Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]} gia' fatturata, non puo' essere eliminata.",
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                else
                  res = Wx::message_box("Confermi la cancellazione?",
                    'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                  if res == Wx::YES
                    ctrl.delete_nota_spese()
                    notify(:evt_nota_spese_changed)
                    # carico gli anni contabili dei progressivi nota spese
                    progressivi_ns = ctrl.load_anni_contabili_progressivi(Models::ProgressivoNotaSpese)
                    notify(:evt_progressivo_ns, progressivi_ns)
                    reset_panel()
                  end

                end
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            else
              Wx::message_box("Licenza scaduta il #{ctrl.licenza.get_data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
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
      
      def btn_pulisci_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def reset_nota_spese_command_state()
        if nota_spese.new_record?
          enable_widgets [btn_salva,btn_cliente,btn_variazione]
          disable_widgets [btn_elimina]
        else
          if ctrl.movimenti_in_sospeso?
            disable_widgets [btn_cliente,btn_variazione]
          else
            enable_widgets [btn_cliente,btn_variazione]
          end
          if nota_spese.fatturata?
            disable_widgets [btn_salva,btn_elimina]
          else
            enable_widgets [btn_salva,btn_elimina]
          end
        end
      end

      def cliente?
        if self.cliente.new_record?
          Wx::message_box('Selezionare un cliente',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
            
          btn_cliente.set_focus()
          return false
        else
          return true
        end

      end

      def check_ritenuta()
        if chk_ritenuta_flag.checked? and lku_ritenuta.view_data.nil?
          Wx::message_box('Inserire un codice ritenuta valido, oppure premere F5',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
            
          lku_ritenuta.activate()
          return false
        else
          return true
        end
      end

      def nota_spese_sql_criteria
        nil
      end
      
      def stampa_nota_spese
        if self.nota_spese.new_record?
          Wx::message_box("Per avviare il processo di stampa è necessario salvare il documento.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
        else
          Wx::BusyCursor.busy() do

            dati_azienda = Models::Azienda.current.dati_azienda
            ns = Models::NotaSpese.find(self.nota_spese.id, :include => [:cliente, {:righe_nota_spese => [:aliquota]}])

            generate(Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i].gsub(' ', '').underscore,
              :margin_top => 90,
              :margin_bottom => 65,
              :dati_azienda => dati_azienda,
              :ns => ns
            )

          end
        end
      end

      def stampa_documenti(docs)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda
          docs.each do |d|
            ns = Models::NotaSpese.find(d, :include => [:cliente, {:righe_nota_spese => [:aliquota]}])

            reset_panel()

            self.nota_spese = ns
            self.cliente = self.nota_spese.cliente
            transfer_cliente_to_view()
            transfer_nota_spese_to_view()
            chce_anno.view_data = self.nota_spese.data_emissione.to_s(:year)

            ns_righe_fattura_panel.display_righe_nota_spese(self.nota_spese)
            ns_righe_fattura_panel.riepilogo_nota_spese()

            generate(d,
              :margin_top => 90,
              :margin_bottom => 65,
              :dati_azienda => dati_azienda,
              :ns => ns,
              :preview => false
            )

          end

          reset_panel()

          merge_all(docs,
            :output => Models::NotaSpese::INTESTAZIONE_PLURALE[configatron.pre_fattura.intestazione.to_i].gsub(' ', '').underscore
          )

        end
      end

      def render_header(opts={})

        dati_azienda = opts[:dati_azienda]
        ns = opts[:ns]

        unless dati_azienda.logo.blank?
          logo_path = File.join(Helpers::ApplicationHelper::WXBRA_IMAGES_PATH, ('logo.' << dati_azienda.logo_tipo))
          open(logo_path, "wb") {|io| io.write(dati_azienda.logo) }
        end

        header.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::NotaSpeseHeaderTemplatePath)
          ).result(binding)
        )

     end

      def render_body(opts={})
        dati_azienda = opts[:dati_azienda]
        ns = opts[:ns]

        body.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::NotaSpeseBodyTemplatePath)
          ).result(binding)
        )
      end

      def render_footer(opts={})
        totali = []
        dati_azienda = opts[:dati_azienda]
        ns = opts[:ns]

        # dati footer
        riepilogo_importi = ns_righe_fattura_panel.riepilogo_importi
        aliquote = ns_righe_fattura_panel.lku_aliquota.instance_hash
        totale_imponibile = ns_righe_fattura_panel.totale_imponibile
        totale_iva = ns_righe_fattura_panel.totale_iva
        totale_nota_spese = ns_righe_fattura_panel.totale_nota_spese
        totale_ritenuta = ns_righe_fattura_panel.totale_ritenuta

        riepilogo_imposte = []
        riepilogo_importi.each_pair do |key, importo|
          riepilogo_imposte << OpenStruct.new({:codice => aliquote[key].codice,
              :descrizione => aliquote[key].descrizione,
              :imponibile => Helpers::ApplicationHelper.currency(importo),
              :totale => Helpers::ApplicationHelper.currency(((importo * aliquote[key].percentuale) / 100))})
        end

        totali << OpenStruct.new({:descrizione => 'Imponibile',
            :importo => Helpers::ApplicationHelper.currency(totale_imponibile)})

        totali << OpenStruct.new({:descrizione => 'Iva',
            :importo => Helpers::ApplicationHelper.currency(totale_iva)})

        totali << OpenStruct.new({:descrizione => 'TOTALE',
            :importo => Helpers::ApplicationHelper.currency(totale_nota_spese)})

        if ritenuta = ns.ritenuta
          totali << OpenStruct.new({:descrizione => "Ritenuta #{Helpers::ApplicationHelper.percentage(ritenuta.percentuale, 0)}",
              :importo => Helpers::ApplicationHelper.currency(totale_ritenuta)})

          totali << OpenStruct.new({:descrizione => "NETTO A PAGARE",
              :importo => Helpers::ApplicationHelper.currency(totale_nota_spese - totale_ritenuta)})

        end

        footer.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::NotaSpeseFooterTemplatePath)
          ).result(binding)
        )

      end

#      def stampa_nota_spese_odf
#        if self.nota_spese.new_record?
#          Wx::message_box("Per avviare il processo di stampa è necessario salvare il documento.",
#            'Info',
#            Wx::OK | Wx::ICON_INFORMATION, self)
#        else
#          Wx::BusyCursor.busy() do
#
#            dati_azienda = Models::Azienda.current.dati_azienda
#            ns = Models::NotaSpese.find(self.nota_spese.id, :include => [:cliente, {:righe_nota_spese => [:aliquota]}])
#
#            if configatron.attivita == Models::Azienda::ATTIVITA[:commercio]
#              if dati_azienda.logo.blank?
#                template = Helpers::FatturazioneHelper::NotaSpeseCommercioTemplatePath
#              else
#                template = Helpers::FatturazioneHelper::NotaSpeseCommercioLogoTemplatePath
#              end
#            else
#              if dati_azienda.logo.blank?
#                template = Helpers::FatturazioneHelper::NotaSpeseServiziTemplatePath
#              else
#                template = Helpers::FatturazioneHelper::NotaSpeseServiziLogoTemplatePath
#              end
#            end
#
#            generate(template, ns)
#
#          end
#        end
#      end
#
#      def render_header_odf(report, ns=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        dati_mittente = []
#        if configatron.fatturazione.carta_intestata
#          report.add_field :mittente, ''
#          1.upto(3) do
#            dati_mittente << OpenStruct.new({:descrizione => ''})
#          end
#        else
#          if dati_azienda.logo.blank?
#            report.add_field :mittente, dati_azienda.denominazione
#            dati_mittente << OpenStruct.new({:descrizione => dati_azienda.indirizzo})
#            dati_mittente << OpenStruct.new({:descrizione => [dati_azienda.cap, dati_azienda.citta].join(' ')})
#            dati_mittente << OpenStruct.new({:descrizione => ['P.Iva', dati_azienda.p_iva, 'C.F.', dati_azienda.cod_fisc].join(' ')})
#          else
#            filename = File.join(Helpers::ApplicationHelper::WXBRA_IMAGES_PATH, ('logo.' << dati_azienda.logo_tipo))
#            open(filename, "wb") {|io| io.write(dati_azienda.logo) }
#            report.add_image :logo, filename
#          end
#        end
#
#        report.add_table("Mittente", dati_mittente) do  |t|
#          t.add_column(:dati_mittente, :descrizione)
#        end
#
#        report.add_field :destinatario, Helpers::ApplicationHelper.truncate(cliente.denominazione, :length => 35, :omission => '')
#
#        dati_destinatario = []
#
#        dati_destinatario << OpenStruct.new({:descrizione => Helpers::ApplicationHelper.truncate(cliente.indirizzo, :length => 35, :omission => '')})
#        dati_destinatario << OpenStruct.new({:descrizione => [cliente.cap, cliente.citta].join(' ')})
#        dati_destinatario << OpenStruct.new({:descrizione => ['P.Iva', cliente.p_iva, 'C.F.', cliente.cod_fisc].join(' ')})
#
#        report.add_table("Destinatario", dati_destinatario) do  |t|
#          t.add_column(:dati_destinatario, :descrizione)
#        end
#
#        report.add_field :fattura_luogo, (dati_azienda.citta + ' li,')
#        report.add_field :fattura_data, ns.data_emissione.to_s(:italian_date)
#
#        report.add_field :fattura_desc, Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]
#        report.add_field :fattura_num, ns.num + '/' + ns.data_emissione.to_s(:short_year)
#
#      end
#
#      def render_body_odf(report, ns=nil)
#        if configatron.attivita == Models::Azienda::ATTIVITA[:commercio]
#          report.add_table("Articoli", ns.righe_nota_spese, :header=>true) do |t|
#            t.add_column(:descrizione)
#            t.add_column(:qta) {|row| (row.qta.zero?) ? '' : row.qta.to_s}
#            t.add_column(:prezzo_u) {|row| (row.importo.zero?) ? '' : Helpers::ApplicationHelper.currency(row.importo)}
#            t.add_column(:prezzo_t) do |row|
#              importo_t = nil
#              if row.qta.zero?
#                importo_t = row.importo unless row.importo.zero?
#              else
#                importo_t = (row.qta * row.importo)
#              end
#              (importo_t.nil?) ? '' :  Helpers::ApplicationHelper.currency(importo_t)
#            end
#            t.add_column(:cod_iva) {|row| row.aliquota.codice}
#          end
#        else
#          report.add_table("Articoli", ns.righe_nota_spese, :header=>true) do |t|
#            t.add_column(:descrizione)
#            t.add_column(:importo) do |row|
#              if row.importo_iva?
#                Helpers::ApplicationHelper.currency(row.importo)
#              else
#                (row.importo.zero?) ? '' :  Helpers::ApplicationHelper.currency(row.importo)
#              end
#            end
#          end
#        end
#      end
#
#      def render_footer_odf(report, ns=nil)
#        totali = []
#
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        # dati footer
#        riepilogo_importi = ns_righe_fattura_panel.riepilogo_importi
#        aliquote = ns_righe_fattura_panel.lku_aliquota.instance_hash
#        totale_imponibile = ns_righe_fattura_panel.totale_imponibile
#        totale_iva = ns_righe_fattura_panel.totale_iva
#        totale_nota_spese = ns_righe_fattura_panel.totale_nota_spese
#        totale_ritenuta = ns_righe_fattura_panel.totale_ritenuta
#
#        riepilogo_imposte = []
#        riepilogo_importi.each_pair do |key, importo|
#          riepilogo_imposte << OpenStruct.new({:codice => aliquote[key].codice,
#              :descrizione => aliquote[key].descrizione,
#              :imponibile => Helpers::ApplicationHelper.currency(importo),
#              :totale => Helpers::ApplicationHelper.currency(((importo * aliquote[key].percentuale) / 100))})
#        end
#
#        report.add_table("RiepilogoImposte", riepilogo_imposte, :header=>true) do  |t|
#          t.add_column(:codice_imposta, :codice)
#          t.add_column(:descrizione_imposta, :descrizione)
#          t.add_column(:imponibile_imposta, :imponibile)
#          t.add_column(:totale_imposta, :totale)
#        end
#
#        totali << OpenStruct.new({:descrizione => 'Imponibile',
#            :importo => Helpers::ApplicationHelper.currency(totale_imponibile)})
#
#        totali << OpenStruct.new({:descrizione => 'Iva',
#            :importo => Helpers::ApplicationHelper.currency(totale_iva)})
#
#        totali << OpenStruct.new({:descrizione => 'TOTALE',
#            :importo => Helpers::ApplicationHelper.currency(totale_nota_spese)})
#
#        if ritenuta = ns.ritenuta
#          totali << OpenStruct.new({:descrizione => "Ritenuta #{Helpers::ApplicationHelper.percentage(ritenuta.percentuale, 0)}",
#              :importo => Helpers::ApplicationHelper.currency(totale_ritenuta)})
#
#          totali << OpenStruct.new({:descrizione => "NETTO A PAGARE",
#              :importo => Helpers::ApplicationHelper.currency(totale_nota_spese - totale_ritenuta)})
#
#        end
#
#        report.add_table("Totali", totali) do  |t|
#          t.add_column(:totale_descrizione, :descrizione)
#          t.add_column(:totale_importo, :importo)
#        end
#
#        unless configatron.fatturazione.carta_intestata
#          unless dati_azienda.logo.blank?
#            dati_mittente = ''
#            dati_mittente << [dati_azienda.denominazione, dati_azienda.indirizzo, dati_azienda.cap, dati_azienda.citta, 'P.Iva', dati_azienda.p_iva, 'C.F.', dati_azienda.cod_fisc].join(' ')
#            report.add_field :dati_mittente, dati_mittente
#          end
#        end
#
#        dati_aggiuntivi = ''
#        dati_aggiuntivi << ['Tel.', dati_azienda.telefono, 'Fax', dati_azienda.fax].join(' ')
#        dati_aggiuntivi << ' E-mail ' + dati_azienda.e_mail unless dati_azienda.e_mail.blank?
#        dati_aggiuntivi << ' IBAN ' + dati_azienda.iban unless dati_azienda.iban.blank?
#
#        report.add_field :dati_aggiuntivi, dati_aggiuntivi
#        report.add_field :cap_soc, Helpers::ApplicationHelper.currency(dati_azienda.cap_soc)
#        report.add_field :reg_imp_citta, dati_azienda.reg_imprese
#        report.add_field :reg_imp_num, dati_azienda.num_reg_imprese
#        report.add_field :rea_num, dati_azienda.num_rea
#
#      end
      
    end
  end
end