# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/fatturazione/righe_ddt_panel'
require 'app/views/dialog/ddt_dialog'

module Views
  module Fatturazione
    module DdtPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      #include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      def ui(container=nil)

        model :cliente => {:attrs => [:denominazione, :p_iva]},
          :ddt => {:attrs => [:num,
                              :data_emissione,
                              :mezzo_trasporto,
                              :causale,
                              :nome_cess,
                              :indirizzo_cess,
                              :cap_cess,
                              :citta_cess,
                              :nome_dest,
                              :indirizzo_dest,
                              :cap_dest,
                              :citta_dest,
                              :nome_vett,
                              :indirizzo_vett,
                              :cap_vett,
                              :citta_vett,
                              :mezzo_vett,
                              :aspetto_beni,
                              :num_colli,
                              :peso,
                              :porto
                            ]}
        
        controller :fatturazione

        logger.debug('initializing NSFatturaPanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_num', self, :extends => TextField)
        xrc.find('txt_data_emissione', self, :extends => DateField)
        xrc.find('txt_mezzo_trasporto', self, :extends => TextField)
        xrc.find('txt_causale', self, :extends => TextField)
        
        xrc.find('txt_nome_cess', self, :extends => TextField)
        xrc.find('txt_indirizzo_cess', self, :extends => TextField)
        xrc.find('txt_cap_cess', self, :extends => TextNumericField)
        xrc.find('txt_citta_cess', self, :extends => TextField)
        
        xrc.find('txt_nome_dest', self, :extends => TextField)
        xrc.find('txt_indirizzo_dest', self, :extends => TextField)
        xrc.find('txt_cap_dest', self, :extends => TextNumericField)
        xrc.find('txt_citta_dest', self, :extends => TextField)
        
        xrc.find('txt_nome_vett', self, :extends => TextField)
        xrc.find('txt_indirizzo_vett', self, :extends => TextField)
        xrc.find('txt_cap_vett', self, :extends => TextNumericField)
        xrc.find('txt_citta_vett', self, :extends => TextField)
        xrc.find('txt_mezzo_vett', self, :extends => TextField)
        
        xrc.find('txt_aspetto_beni', self, :extends => TextField)
        xrc.find('txt_num_colli', self, :extends => TextNumericField)
        xrc.find('txt_peso', self, :extends => DecimalField)
        xrc.find('txt_porto', self, :extends => TextField)

        xrc.find('btn_cliente', self)
        xrc.find('btn_fornitore', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_stampa', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)

        map_events(self)

        xrc.find('RIGHE_DDT_PANEL', container, 
          :extends => Views::Fatturazione::RigheDdtPanel, 
          :force_parent => self)

        righe_ddt_panel.ui()
        
        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      # inizializza il numero ddt
      def init_panel()

        # calcolo il progressivo
        txt_num.view_data = Models::ProgressivoDdt.next_sequence(Date.today.year) if txt_num.view_data.blank?
        # imposto la data di oggi
        txt_data_emissione.view_data = Date.today if txt_data_emissione.view_data.blank?
        
        reset_ddt_command_state()

        righe_ddt_panel.init_panel()
        
        txt_num.enabled? ? txt_num.activate() : righe_ddt_panel.txt_qta.activate()
      end
      
      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_cliente()
          reset_ddt()
          
          # calcolo il progressivo
          txt_num.view_data = Models::ProgressivoDdt.next_sequence(Date.today.year)

          # imposto la data di oggi
          txt_data_emissione.view_data = Date.today

          enable_widgets [
            txt_num,
            txt_data_emissione,
          ]

          reset_ddt_command_state()

          righe_ddt_panel.reset_panel()

          txt_num.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def btn_cliente_click(evt)
        begin
          Wx::BusyCursor.busy() do
            clienti_dlg = Views::Dialog::ClientiDialog.new(self)
            clienti_dlg.center_on_screen(Wx::BOTH)
            answer = clienti_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_panel()
              self.cliente = ctrl.load_cliente(clienti_dlg.selected)
              self.ddt.cliente = self.cliente
              transfer_cliente_to_view()
              transfer_cessionario_to_view()
              txt_num.activate()
            elsif answer == clienti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:cliente, [Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW, Helpers::FatturazioneHelper::WXBRA_DDT_FOLDER])
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

      def btn_fornitore_click(evt)
        begin
          Wx::BusyCursor.busy() do
            fornitori_dlg = Views::Dialog::FornitoriDialog.new(self)
            fornitori_dlg.center_on_screen(Wx::BOTH)
            answer = fornitori_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_panel()
              self.cliente = ctrl.load_fornitore(fornitori_dlg.selected)
              self.ddt.cliente = self.cliente
              transfer_cliente_to_view()
              transfer_cessionario_to_view()
              txt_num.activate()
            elsif answer == fornitori_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:fornitore, [Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW, Helpers::FatturazioneHelper::WXBRA_DDT_FOLDER])
              # This sends the event for processing by listeners
              process_event(evt_new)
            else
              logger.debug("You pressed Cancel")
            end

            fornitori_dlg.destroy()
          end
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
            ddt_dlg = Views::Dialog::DdtDialog.new(self)
            ddt_dlg.center_on_screen(Wx::BOTH)
            if ddt_dlg.show_modal() == Wx::ID_OK
              self.ddt = ctrl.load_ddt(ddt_dlg.selected)
              self.cliente = self.ddt.cliente
              transfer_cliente_to_view()
              transfer_ddt_to_view()
              righe_ddt_panel.display_righe_ddt(self.ddt)

              disable_widgets [
                txt_num,
                txt_data_emissione,
              ]

              reset_ddt_command_state()
              righe_ddt_panel.txt_qta.activate()

            else
              logger.debug("You pressed Cancel")
            end

            ddt_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_stampa_click(evt)
        begin
          stampa_ddt()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
        
      end
      
      def btn_salva_click(evt)
        begin
          # per controllare il tasto funzione F8 associato al salva
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if ctrl.licenza.attiva?
                if can? :write, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
                  transfer_ddt_from_view()
                  if cliente?
                    unless ddt.num.strip.match(/^[0-9]*$/)
                      res = Wx::message_box("La documento che si sta salvando non segue la numerazione standard:\nnon verra' fatto alcun controllo sulla validita'.\nProcedo con il savataggio dei dati?",
                        'Avvertenza',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res == Wx::NO
                        return
                      end
                    end

                    if self.ddt.valid?
                      ctrl.save_ddt()

                      # carico gli anni contabili dei progressivi ddt
                      progressivi_ddt = ctrl.load_anni_contabili_progressivi(Models::ProgressivoDdt)
                      notify(:evt_progressivo_ddt, progressivi_ddt)

                      Wx::message_box('Salvataggio avvenuto correttamente',
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      res_stampa = Wx::message_box("Vuoi stampare il documento?",
                        'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res_stampa == Wx::YES
                        stampa_ddt()
                      end

                      reset_panel()
                    else
                      Wx::message_box(self.ddt.error_msg,
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      focus_ddt_error_field()

                    end
                  end
                else
                  Wx::message_box('Utente non autorizzato.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                end
              else
                Wx::message_box("Licenza scaduta il #{ctrl.licenza.data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
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
                res = Wx::message_box("Confermi la cancellazione?",
                  'Domanda',
                    Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                if res == Wx::YES
                  ctrl.delete_ddt()

                  # carico gli anni contabili dei progressivi ddt
                  progressivi_ddt = ctrl.load_anni_contabili_progressivi(Models::ProgressivoDdt)
                  notify(:evt_progressivo_ddt, progressivi_ddt)

                  reset_panel()
                end
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
            else
              Wx::message_box("Licenza scaduta il #{ctrl.licenza.data_scadenza.to_s(:italian_date)}. Rinnovare la licenza. ",
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
          righe_ddt_panel.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def reset_ddt_command_state()
        if ddt.new_record?
          disable_widgets [btn_elimina]
        else
          enable_widgets [btn_elimina]
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

      def stampa_ddt
        if self.ddt.new_record?
          Wx::message_box("Per avviare il processo di stampa è necessario salvare il documento.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
        else
          Wx::BusyCursor.busy() do

            dati_azienda = Models::Azienda.current.dati_azienda
            documento = Models::Ddt.find(self.ddt.id, :include => [:cliente, :righe_ddt])

            generate(:ddt,
              :margin_top => 80,
              :margin_bottom => 80,
              :dati_azienda => dati_azienda,
              :documento => documento
            )

          end
        end
      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]
        documento = opts[:documento]

        unless dati_azienda.logo.blank?
          logo_path = File.join(Helpers::ApplicationHelper::WXBRA_IMAGES_PATH, ('logo.' << dati_azienda.logo_tipo))
          open(logo_path, "wb") {|io| io.write(dati_azienda.logo) }
        end

        header.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::DdtHeaderTemplatePath)
          ).result(binding)
        )

      end

      def render_body(opts={})
        dati_azienda = opts[:dati_azienda]
        documento = opts[:documento]

        body.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::DdtBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        dati_azienda = opts[:dati_azienda]
        documento = opts[:documento]

        footer.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::DdtFooterTemplatePath)
          ).result(binding)
        )

      end
      
#      def stampa_ddt_odf
#        if self.ddt.new_record?
#          Wx::message_box("Per avviare il processo di stampa è necessario salvare il documento.",
#            'Info',
#            Wx::OK | Wx::ICON_INFORMATION, self)
#        else
#          Wx::BusyCursor.busy() do
#
#            dati_azienda = Models::Azienda.current.dati_azienda
#            documento = Models::Ddt.find(self.ddt.id, :include => [:cliente, :righe_ddt])
#
#            if dati_azienda.logo.blank?
#              template = Helpers::FatturazioneHelper::DdtTemplatePath
#            else
#              template = Helpers::FatturazioneHelper::DdtTemplateLogoPath
#            end
#
#            generate(template, documento)
#          end
#        end
#      end
#
#      def render_header(report, documento=nil)
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
#
#        report.add_field :num_ddt, documento.num
#        report.add_field :data_ddt, documento.data_emissione.to_s(:italian_date)
#        report.add_field :mezzo, documento.mezzo_trasporto
#
#        report.add_field :cessionario, [documento.nome_cess, "\n", documento.indirizzo_cess, "\n", documento.cap_cess, ' ', documento.citta_cess].join()
#        report.add_field :destinatario, [documento.nome_dest, "\n", documento.indirizzo_dest, "\n", documento.cap_dest, ' ', documento.citta_dest].join()
#
#        report.add_field :causale, documento.causale
#
#      end
#
#      def render_body(report, documento=nil)
#        report.add_table("Articoli", documento.righe_ddt, :header=>true) do |t|
#          t.add_column(:qta) {|row| row.qta.to_s}
#          t.add_column(:descrizione)
#        end
#      end
#
#      def render_footer(report, documento=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        report.add_field :aspetto, documento.aspetto_beni
#        report.add_field :colli, documento.num_colli
#        report.add_field :peso, documento.peso
#        report.add_field :porto, documento.porto
#        report.add_field :vettore, [documento.nome_vett, "\n", documento.indirizzo_vett, "\n", documento.cap_vett, ' ', documento.citta_vett].join()
#
#        unless configatron.fatturazione.carta_intestata
#          unless dati_azienda.logo.blank?
#            dati_mittente = ''
#            dati_mittente << [dati_azienda.denominazione, dati_azienda.indirizzo, dati_azienda.cap, dati_azienda.citta, 'P.Iva', dati_azienda.p_iva, 'C.F.', dati_azienda.cod_fisc].join(' ')
#            report.add_field :dati_mittente, dati_mittente
#          end
#        end
#
#      end
      
      def transfer_cessionario_to_view()
          txt_nome_cess.view_data = self.cliente.denominazione
          txt_indirizzo_cess.view_data = self.cliente.indirizzo
          txt_cap_cess.view_data = self.cliente.cap
          txt_citta_cess.view_data = self.cliente.citta
      end
    end
  end
end