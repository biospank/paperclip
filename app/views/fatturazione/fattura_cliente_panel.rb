# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/nota_spese_dialog'
require 'app/views/dialog/fatture_clienti_dialog'
require 'app/views/fatturazione/righe_fattura_cliente_panel'
#require 'odf-report'
require 'ostruct'

module Views
  module Fatturazione
    module FatturaClientePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      #include Helpers::ODF::Report
      include Helpers::Xml
      include Helpers::Wk::HtmlToPdf
      include ERB::Util

      attr_accessor :lista_ns, # mantiene gli identificativi delle note spese associate alla fattura (permette il controllo dei duplicati)
      :dialog_sql_criteria # utilizzato nelle dialog


      def ui(container=nil)

        self.lista_ns = []

        model :cliente => {:attrs => [:denominazione, :p_iva]},
          :fattura_cliente_fatturazione => {:attrs => [:num,
            :data_emissione,
            :tipo_documento,
            :nota_di_credito,
            :ritenuta,
            :tipo_ritenuta,
            :causale_pagamento,
            :destinatario,
            :indirizzo_dest,
            :cap_dest,
            :citta_dest,
            :rif_ddt,
            :rif_pagamento,
            :iva_diff],
          :alias => :fattura_cliente}

        controller :fatturazione

        logger.debug('initializing FatturaClientePanel...')
        xrc = Xrc.instance()
        # Fattura cliente

        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_fattura_cliente_changed) do |data|
          chce_anno.load_data(data, :select => :last)
        end

        xrc.find('txt_num', self, :extends => TextField) do |field|
          field.evt_char { |evt| txt_num_keypress(evt) }
        end
        xrc.find('txt_data_emissione', self, :extends => DateField) do |field|
          field.move_after_in_tab_order(txt_num)
          field.evt_char { |evt| txt_data_emissione_keypress(evt) }
        end

        xrc.find('chce_tipo_documento', self, :extends => ChoiceField)do |chce|
          chce.load_data(Helpers::ApplicationHelper::Fatturazione::TIPI_DOCUMENTO)
        end
        # NumberCheckField per mantenere il tipo di dato altrimenti interferisce con il metodo changed?
        xrc.find('chk_nota_di_credito', self, :extends => NumberCheckField)
        xrc.find('chk_ritenuta_flag', self, :extends => FkCheckField)
        xrc.find('lku_ritenuta', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
            :label => lambda {|ritenuta| self.txt_descrizione_ritenuta.view_data = (ritenuta ? ritenuta.descrizione : nil)},
            :model => :ritenuta,
            :dialog => :ritenute_dialog,
            :default => lambda {|ritenuta| ritenuta.predefinita?},
            :view => Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
            :folder => Helpers::FatturazioneHelper::WXBRA_FATTURA_FOLDER)
        end
        xrc.find('chce_tipo_ritenuta', self, :extends => ChoiceField)do |chce|
          chce.load_data(Helpers::ApplicationHelper::Fatturazione::TIPI_RITENUTA)
        end
        xrc.find('chce_causale_pagamento', self, :extends => ChoiceField)do |chce|
          chce.load_data(Helpers::ApplicationHelper::Fatturazione::CAUSALI_PAGAMENTO)
        end

        subscribe(:evt_ritenuta_changed) do |data|
          lku_ritenuta.load_data(data)
        end

        subscribe(:evt_stampa_fatture) do |fatture|
          stampa_fatture(fatture)
        end

        # notifica dal magazzino
        subscribe(:evt_stampa_fattura) do |fattura|
          self.fattura_cliente = fattura
          self.cliente = fattura.cliente
          transfer_cliente_to_view()
          transfer_fattura_cliente_to_view()
          chce_anno.view_data = fattura.data_emissione.to_s(:year)
          chk_ritenuta_flag.view_data = fattura.ritenuta
          righe_fattura_cliente_panel.display_righe_fattura_cliente(fattura)
          righe_fattura_cliente_panel.riepilogo_fattura()
          stampa_fattura()
          reset_panel()
        end

        xrc.find('txt_descrizione_ritenuta', self, :extends => TextField)

        xrc.find('btn_cliente', self)
        xrc.find('btn_nota_spese', self) do |btn|
          btn.label = Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]
        end

        subscribe(:evt_prefattura_changed) do
          btn_nota_spese.label = Models::NotaSpese::INTESTAZIONE[configatron.pre_fattura.intestazione.to_i]
        end

        subscribe(:evt_dettaglio_fattura_cliente_fatturazione) do |fattura|
          self.fattura_cliente = fattura # importante deve essere di tipo fattura_cliente_fatturazione
          self.cliente = self.fattura_cliente.cliente
          transfer_cliente_to_view()
          transfer_fattura_cliente_to_view()
          chce_anno.view_data = self.fattura_cliente.data_emissione.to_s(:year)

          righe_fattura_cliente_panel.display_righe_fattura_cliente(self.fattura_cliente)
          righe_fattura_cliente_panel.riepilogo_fattura()

          disable_widgets [
            txt_num,
            chce_anno,
            txt_data_emissione,
            chk_nota_di_credito,
            chk_ritenuta_flag,
            lku_ritenuta
          ]

          if fattura_cliente.ha_registrazioni_in_prima_nota?
            Wx::message_box("Fattura non modificabile.",
              'Avvertenza',
              Wx::OK | Wx::ICON_WARNING, self)
          end

          reset_fattura_cliente_command_state()
          righe_fattura_cliente_panel.txt_descrizione.activate()

        end

        xrc.find('btn_variazione', self)
        xrc.find('btn_stampa', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)

        map_events(self)

        case configatron.attivita
        when Models::Azienda::ATTIVITA[:commercio]
          xrc.find('RIGHE_FATTURA_SERVIZI_PANEL', container,
            :force_parent => self)

          righe_fattura_servizi_panel.hide()

          xrc.find('RIGHE_FATTURA_COMMERCIO_PANEL', container,
            :extends => Views::Fatturazione::RigheFatturaCommercioPanel,
            :force_parent => self,
            :alias => :righe_fattura_cliente_panel)

          righe_fattura_commercio_panel.show()


        when Models::Azienda::ATTIVITA[:servizi]
          xrc.find('RIGHE_FATTURA_COMMERCIO_PANEL', container,
            :force_parent => self)

          righe_fattura_commercio_panel.hide()

          xrc.find('RIGHE_FATTURA_SERVIZI_PANEL', container,
            :extends => Views::Fatturazione::RigheFatturaServiziPanel,
            :force_parent => self,
            :alias => :righe_fattura_cliente_panel)

          righe_fattura_servizi_panel.show()

        end

        # dati aggiuntivi
        xrc.find('txt_destinatario', righe_fattura_cliente_panel, :extends => TextField, :force_parent => self)
        xrc.find('txt_indirizzo_dest', righe_fattura_cliente_panel, :extends => TextField, :force_parent => self)
        xrc.find('txt_cap_dest', righe_fattura_cliente_panel, :extends => TextNumericField, :force_parent => self)
        xrc.find('txt_citta_dest', righe_fattura_cliente_panel, :extends => TextField, :force_parent => self)
        xrc.find('txt_rif_ddt', righe_fattura_cliente_panel, :extends => TextField, :force_parent => self)
        xrc.find('txt_rif_pagamento', righe_fattura_cliente_panel, :extends => TextField, :force_parent => self)
        xrc.find('chk_iva_diff', righe_fattura_cliente_panel, :extends => NumberCheckField, :force_parent => self)

        righe_fattura_cliente_panel.ui()

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      # inizializza il numero fattura
      # e gli anni contabili se non sono gia presenti
      def init_panel()
        # carico gli anni contabili
        #        chce_anno.load_data(ctrl.load_anni_contabili(fattura_cliente.class), :select => :last) if chce_anno.empty?

        # calcolo il progressivo
        txt_num.view_data = Models::ProgressivoFatturaCliente.next_sequence(chce_anno.string_selection()) if txt_num.view_data.blank?
        # imposto la data di oggi
        txt_data_emissione.view_data = Date.today if txt_data_emissione.view_data.blank?

        reset_fattura_cliente_command_state()

        righe_fattura_cliente_panel.init_panel()

        txt_num.enabled? ? txt_num.activate() : righe_fattura_cliente_panel.txt_descrizione.activate()
      end

      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_cliente()
          reset_fattura_cliente()

          # resetto la lista delle note spese collegate
          lista_ns.clear()

          # carico gli anni contabili
          chce_anno.load_data(ctrl.load_anni_contabili(fattura_cliente.class), :select => :last) if chce_anno.empty?

          chce_anno.select_last()

          # calcolo il progressivo
          txt_num.view_data = Models::ProgressivoFatturaCliente.next_sequence(chce_anno.string_selection())

          # imposto la data di oggi
          txt_data_emissione.view_data = Date.today

          chk_ritenuta_flag.view_data = nil
          chce_tipo_ritenuta.view_data = nil
          chce_causale_pagamento.view_data = nil

          enable_widgets [
            txt_num,
            chce_anno,
            txt_data_emissione,
            chk_nota_di_credito,
            chk_ritenuta_flag
          ]

          disable_widgets [
            lku_ritenuta,
            chce_tipo_ritenuta,
            chce_causale_pagamento
          ]

          reset_fattura_cliente_command_state()

          righe_fattura_cliente_panel.reset_panel()

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
              righe_fattura_cliente_panel.txt_descrizione.activate()
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
              self.fattura_cliente.cliente = self.cliente
              transfer_cliente_to_view()
              txt_data_emissione.activate()
            elsif answer == clienti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:cliente,
                [
                  Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW,
                  Helpers::FatturazioneHelper::WXBRA_FATTURA_FOLDER
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

      def btn_nota_spese_click(evt)
        begin
          Wx::BusyCursor.busy() do
            # se esiste ricerca solo le occorrenze associate ad un cliente
            transfer_cliente_from_view()
            self.dialog_sql_criteria = self.nota_spese_sql_criteria()
            nota_spese_dlg = Views::Dialog::NotaSpeseDialog.new(self)
            nota_spese_dlg.center_on_screen(Wx::BOTH)
            if nota_spese_dlg.show_modal() == Wx::ID_OK
              nota_spese = ctrl.load_nota_spese(nota_spese_dlg.selected)
              if self.fattura_cliente.new_record?
                self.cliente = self.fattura_cliente.cliente = nota_spese.cliente
                self.fattura_cliente.ritenuta = nota_spese.ritenuta
              end
              self.lista_ns << nota_spese.id
              transfer_cliente_to_view()
              transfer_fattura_cliente_to_view()
              chk_ritenuta_flag.view_data = self.fattura_cliente.ritenuta
              righe_fattura_cliente_panel.build_righe_fattura_cliente(nota_spese)
              righe_fattura_cliente_panel.riepilogo_fattura()

              if self.fattura_cliente.new_record?
                enable_widgets [
                  txt_num,
                  chce_anno,
                  txt_data_emissione,
                  chk_nota_di_credito,
                  chk_ritenuta_flag,
                ]
                if self.fattura_cliente.ritenuta
                  enable_widgets [lku_ritenuta]
                  chk_nota_di_credito.view_data = nil
                end
              else
                disable_widgets [
                  txt_num,
                  chce_anno,
                  txt_data_emissione,
                  chk_nota_di_credito,
                  chk_ritenuta_flag,
                  lku_ritenuta
                ]

              end

              calcola_progressivo(chce_anno.string_selection())
              reset_fattura_cliente_command_state()
              txt_data_emissione.activate()

            end

            nota_spese_dlg.destroy()
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
            txt_data_emissione.view_data = fattura_cliente.data_emissione
          else
            txt_data_emissione.view_data = Date.new(anno.to_i).end_of_year()
          end

          calcola_progressivo(anno)

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def chce_causale_pagamento_select(evt)
        begin

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
            self.dialog_sql_criteria = self.fattura_sql_criteria()
            fattura_cliente_dlg = Views::Dialog::FattureClientiDialog.new(self)
            fattura_cliente_dlg.center_on_screen(Wx::BOTH)
            if fattura_cliente_dlg.show_modal() == Wx::ID_OK
              self.fattura_cliente = ctrl.load_fattura_cliente(fattura_cliente_dlg.selected)
              self.cliente = self.fattura_cliente.cliente
              transfer_cliente_to_view()
              transfer_fattura_cliente_to_view()
              chce_anno.view_data = self.fattura_cliente.data_emissione.to_s(:year)
              chk_ritenuta_flag.view_data = self.fattura_cliente.ritenuta
              righe_fattura_cliente_panel.display_righe_fattura_cliente(self.fattura_cliente)
              righe_fattura_cliente_panel.riepilogo_fattura()

              disable_widgets [
                txt_num,
                chce_anno,
                txt_data_emissione,
                chk_nota_di_credito,
                chk_ritenuta_flag,
                lku_ritenuta
              ]

              if fattura_cliente.ha_registrazioni_in_prima_nota?
                Wx::message_box("Fattura non modificabile.",
                  'Avvertenza',
                  Wx::OK | Wx::ICON_WARNING, self)
              end

              reset_fattura_cliente_command_state()
              righe_fattura_cliente_panel.txt_descrizione.activate()

            else
              logger.debug("You pressed Cancel")
            end

            fattura_cliente_dlg.destroy()
          end
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def btn_stampa_click(evt)
        begin
          stampa_fattura()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()

      end

      def chk_nota_di_credito_click(evt)
        begin
          calcola_progressivo(chce_anno.string_selection())
          if chk_nota_di_credito.checked?
            self.chk_ritenuta_flag.view_data = nil
            self.lku_ritenuta.view_data = nil
            disable_widgets [chk_ritenuta_flag, lku_ritenuta, chce_tipo_ritenuta, chce_causale_pagamento]
            transfer_fattura_cliente_from_view()
            righe_fattura_cliente_panel.riepilogo_fattura()
          else
            enable_widgets [chk_ritenuta_flag]
            transfer_fattura_cliente_from_view()
            righe_fattura_cliente_panel.riepilogo_fattura()
          end

        rescue Exception => e
          log_error(self, e)
        end

      end

      def chk_ritenuta_flag_click(evt)
        begin
          if chk_ritenuta_flag.checked?
            self.chk_nota_di_credito.view_data = false
            disable_widgets [chk_nota_di_credito]
            enable_widgets [lku_ritenuta, chce_tipo_ritenuta, chce_causale_pagamento]
            lku_ritenuta.set_default()
            lku_ritenuta.activate()
            transfer_fattura_cliente_from_view()
            righe_fattura_cliente_panel.riepilogo_fattura()
          else
            enable_widgets [chk_nota_di_credito]
            disable_widgets [lku_ritenuta, chce_tipo_ritenuta, chce_causale_pagamento]
            lku_ritenuta.view_data = nil
            chce_tipo_ritenuta.view_data = nil
            chce_causale_pagamento.view_data = nil
            transfer_fattura_cliente_from_view()
            righe_fattura_cliente_panel.riepilogo_fattura()
          end

        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_ritenuta_after_change()
        begin
          lku_ritenuta.match_selection()
          transfer_fattura_cliente_from_view()
          righe_fattura_cliente_panel.riepilogo_fattura()
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
                  transfer_fattura_cliente_from_view()
                  if cliente? and check_ritenuta()
                    unless fattura_cliente.num.strip.match(/^[0-9]*$/)
                      res = Wx::message_box("La fattura che si sta salvando non segue la numerazione standard:\nnon verra' fatto alcun controllo sulla validita'.\nProcedo con il savataggio dei dati?",
                        'Avvertenza',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res == Wx::NO
                        txt_num.activate()
                        return
                      end
                    end

                    if fattura_cliente.data_emissione.future?
                      res = Wx::message_box("La data di emissione è maggiore della data odierna: Confermi?",
                        'Avvertenza',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res == Wx::NO
                        txt_data_emissione.activate()
                        return
                      end
                    end

                    if self.fattura_cliente.valid?
                      ctrl.save_fattura_cliente()

                      notify(:evt_fattura_changed)
                      # carico gli anni contabili dei progressivi fattura
                      progressivi_fattura = ctrl.load_anni_contabili_progressivi(Models::ProgressivoFatturaCliente)
                      notify(:evt_progressivo_fattura, progressivi_fattura)
                      # carico gli anni contabili dei progressivi nota di credito
                      progressivi_nc = ctrl.load_anni_contabili_progressivi(Models::ProgressivoNc)
                      notify(:evt_progressivo_nc, progressivi_nc)

                      Wx::message_box('Salvataggio avvenuto correttamente',
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      res_stampa = Wx::message_box("Vuoi stampare la fattura?",
                        'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res_stampa == Wx::YES
                        stampa_fattura()
                      end

                      reset_panel()
                    else
                      Wx::message_box(self.fattura_cliente.error_msg,
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      focus_fattura_cliente_error_field()

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
                if fattura_cliente.ha_registrazioni_in_prima_nota?
                  Wx::message_box("La fattura e' stata registrata in prima nota e non puo' essere eliminata.",
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                else
                  res = Wx::message_box("Confermi la cancellazione?",
                    'Domanda',
                    Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                  if res == Wx::YES
                    ctrl.delete_fattura_cliente()
                    notify(:evt_fattura_changed)
                    # carico gli anni contabili dei progressivi fattura
                    progressivi_fattura = ctrl.load_anni_contabili_progressivi(Models::ProgressivoFatturaCliente)
                    notify(:evt_progressivo_fattura, progressivi_fattura)
                    # carico gli anni contabili dei progressivi nota di credito
                    progressivi_nc = ctrl.load_anni_contabili_progressivi(Models::ProgressivoNc)
                    notify(:evt_progressivo_nc, progressivi_nc)
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

      def reset_fattura_cliente_command_state()
        if fattura_cliente.new_record?
          enable_widgets [btn_salva,btn_cliente,btn_variazione]
          disable_widgets [btn_elimina]
        else
          if ctrl.movimenti_in_sospeso?
            disable_widgets [btn_cliente,btn_variazione]
          else
            enable_widgets [btn_cliente,btn_variazione]
          end
          if fattura_cliente.ha_registrazioni_in_prima_nota?
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

        if chk_ritenuta_flag.checked? and chce_tipo_ritenuta.view_data.nil?
          Wx::message_box('Selezionare un tipo ritenuta',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          chce_tipo_ritenuta.activate()
          return false
        else
          return true
        end

        if chk_ritenuta_flag.checked? and chce_causale_pagamento.view_data.nil?
          Wx::message_box('Selezionare una causale pagamento',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          chce_causale_pagamento.activate()
          return false
        else
          return true
        end
      end

      def nota_spese_sql_criteria
        "fattura_cliente_id is null"
      end

      def fattura_sql_criteria
        "(da_scadenzario = 0 or da_scadenzario = 1) and da_fatturazione = 1"
      end

      def nota_spese_associata?(id_ns)
        self.lista_ns.detect {|id| id == id_ns} != nil
      end

      private

      def calcola_progressivo(anno)
        if chk_nota_di_credito.checked?
          txt_num.view_data = Models::ProgressivoNc.next_sequence(anno)
        else
          txt_num.view_data = Models::ProgressivoFatturaCliente.next_sequence(anno)
        end

      end

#      def stampa_fattura_odf
#        if self.fattura_cliente.new_record?
#          Wx::message_box("Per avviare il processo di stampa è necessario salvare la fattura.",
#            'Info',
#            Wx::OK | Wx::ICON_INFORMATION, self)
#        else
#          Wx::BusyCursor.busy() do
#
#            dati_azienda = Models::Azienda.current.dati_azienda
#            fattura = Models::FatturaClienteFatturazione.find(self.fattura_cliente.id, :include => [:cliente, {:righe_fattura_cliente => [:aliquota]}])
#
#            if configatron.attivita == Models::Azienda::ATTIVITA[:commercio]
#              if dati_azienda.logo.blank?
#                template = Helpers::FatturazioneHelper::FatturaCommercioTemplatePath
#              else
#                template = Helpers::FatturazioneHelper::FatturaCommercioLogoTemplatePath
#              end
#            else
#              if dati_azienda.logo.blank?
#                template = Helpers::FatturazioneHelper::FatturaServiziTemplatePath
#              else
#                template = Helpers::FatturazioneHelper::FatturaServiziLogoTemplatePath
#              end
#            end
#
#            generate(template, fattura)
#
#          end
#        end
#      end

      def stampa_fattura
        if self.fattura_cliente.new_record?
          Wx::message_box("Per avviare il processo di stampa è necessario salvare la fattura.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
        else
          Wx::BusyCursor.busy() do

            dati_azienda = Models::Azienda.current.dati_azienda
            fattura = Models::FatturaClienteFatturazione.find(self.fattura_cliente.id, :include => [:cliente, {:righe_fattura_cliente => [:aliquota]}])

            generate_xml(:fattura,
              :dati_azienda => dati_azienda,
              :fattura => fattura
            )
            generate(:fattura,
              :margin_top => 90,
              :margin_bottom => 65,
              :dati_azienda => dati_azienda,
              :fattura => fattura
            )

          end
        end
      end

      def stampa_fatture(fatture)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda
          fatture.each do |f|
            fattura = Models::FatturaClienteFatturazione.find(f, :include => [:cliente, {:righe_fattura_cliente => [:aliquota]}])

            reset_panel()

            self.fattura_cliente = fattura
            self.cliente = fattura.cliente
            transfer_cliente_to_view()
            transfer_fattura_cliente_to_view()
            chce_anno.view_data = fattura.data_emissione.to_s(:year)
            chk_ritenuta_flag.view_data = fattura.ritenuta
            righe_fattura_cliente_panel.display_righe_fattura_cliente(fattura)
            righe_fattura_cliente_panel.riepilogo_fattura()

            generate(f.to_s,
              :margin_top => 90,
              :margin_bottom => 65,
              :dati_azienda => dati_azienda,
              :fattura => fattura,
              :preview => false
            )

          end

          reset_panel()

          merge_all(fatture,
            :output => :fatture
          )

        end
      end

      def render_xml(opts={})
        dati_azienda = opts[:dati_azienda]
        fattura = opts[:fattura]

        # dati footer
        riepilogo_importi = righe_fattura_cliente_panel.riepilogo_importi
        aliquote = righe_fattura_cliente_panel.lku_aliquota.instance_hash
        totale_imponibile = righe_fattura_cliente_panel.totale_imponibile
        totale_iva = righe_fattura_cliente_panel.totale_iva
        totale_fattura = righe_fattura_cliente_panel.totale_fattura
        totale_ritenuta = righe_fattura_cliente_panel.totale_ritenuta

        riepilogo_imposte = []
        riepilogo_importi.each_pair do |key, importo|
          riepilogo_imposte << OpenStruct.new({:percentuale => aliquote[key].percentuale,
              :descrizione => aliquote[key].descrizione,
              :imponibile => Helpers::ApplicationHelper.number_text(importo),
              :totale => Helpers::ApplicationHelper.number_text(((importo * aliquote[key].percentuale) / 100))})
        end

        totali = []
        totali << OpenStruct.new({:descrizione => 'Imponibile',
            :importo => Helpers::ApplicationHelper.currency(totale_imponibile)})

        totali << OpenStruct.new({:descrizione => 'Iva',
            :importo => Helpers::ApplicationHelper.currency(totale_iva)})

        totali << OpenStruct.new({:descrizione => 'TOTALE',
            :importo => Helpers::ApplicationHelper.currency(totale_fattura)})

        if ritenuta = fattura.ritenuta
          totali << OpenStruct.new({:descrizione => "Ritenuta #{Helpers::ApplicationHelper.percentage(ritenuta.percentuale, 0)}",
              :importo => Helpers::ApplicationHelper.currency(totale_ritenuta)})

          totali << OpenStruct.new({:descrizione => "NETTO A PAGARE",
              :importo => Helpers::ApplicationHelper.currency(totale_fattura - totale_ritenuta)})

        end

        xml.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FatturaXmlTemplatePath)
          ).result(binding)
        )
      end

      def render_header(opts={})

        dati_azienda = opts[:dati_azienda]
        fattura = opts[:fattura]

        unless dati_azienda.logo.blank?
          logo_path = File.join(Helpers::ApplicationHelper::WXBRA_IMAGES_PATH, ('logo.' << dati_azienda.logo_tipo))
          open(logo_path, "wb") {|io| io.write(dati_azienda.logo) }
        end

        header.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FatturaHeaderTemplatePath)
          ).result(binding)
        )

     end

      def render_body(opts={})
        dati_azienda = opts[:dati_azienda]
        fattura = opts[:fattura]

        body.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FatturaBodyTemplatePath)
          ).result(binding)
        )
      end

      def render_footer(opts={})
        dati_azienda = opts[:dati_azienda]
        fattura = opts[:fattura]

        # dati footer
        riepilogo_importi = righe_fattura_cliente_panel.riepilogo_importi
        aliquote = righe_fattura_cliente_panel.lku_aliquota.instance_hash
        totale_imponibile = righe_fattura_cliente_panel.totale_imponibile
        totale_iva = righe_fattura_cliente_panel.totale_iva
        totale_fattura = righe_fattura_cliente_panel.totale_fattura
        totale_ritenuta = righe_fattura_cliente_panel.totale_ritenuta

        riepilogo_imposte = []
        riepilogo_importi.each_pair do |key, importo|
          riepilogo_imposte << OpenStruct.new({:codice => aliquote[key].codice,
              :descrizione => aliquote[key].descrizione,
              :imponibile => Helpers::ApplicationHelper.currency(importo),
              :totale => Helpers::ApplicationHelper.currency(((importo * aliquote[key].percentuale) / 100))})
        end

        totali = []
        totali << OpenStruct.new({:descrizione => 'Imponibile',
            :importo => Helpers::ApplicationHelper.currency(totale_imponibile)})

        totali << OpenStruct.new({:descrizione => 'Iva',
            :importo => Helpers::ApplicationHelper.currency(totale_iva)})

        totali << OpenStruct.new({:descrizione => 'TOTALE',
            :importo => Helpers::ApplicationHelper.currency(totale_fattura)})

        if ritenuta = fattura.ritenuta
          totali << OpenStruct.new({:descrizione => "Ritenuta #{Helpers::ApplicationHelper.percentage(ritenuta.percentuale, 0)}",
              :importo => Helpers::ApplicationHelper.currency(totale_ritenuta)})

          totali << OpenStruct.new({:descrizione => "NETTO A PAGARE",
              :importo => Helpers::ApplicationHelper.currency(totale_fattura - totale_ritenuta)})

        end

        footer.write(
          ERB.new(
            IO.read(Helpers::FatturazioneHelper::FatturaFooterTemplatePath)
          ).result(binding)
        )

      end

#      def render_header_odf(report, fattura=nil)
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
#        if configatron.attivita == Models::Azienda::ATTIVITA[:commercio]
#          report.add_field :rif_ddt, fattura.rif_ddt
#          report.add_field :rif_pagamento, fattura.rif_pagamento
#        else
#          if fattura.rif_pagamento.blank?
#            report.add_field :rif_pagamento, ''
#          else
#            report.add_field :rif_pagamento, "Pagamento\n" + fattura.rif_pagamento
#          end
#        end
#
#        report.add_field :destinatario, Helpers::ApplicationHelper.truncate(cliente.denominazione, :length => 65, :omission => '')
#
#        dati_destinatario = []
#
#        #dati_destinatario << OpenStruct.new({:descrizione => cliente.denominazione})
#        dati_destinatario << OpenStruct.new({:descrizione => Helpers::ApplicationHelper.truncate(cliente.indirizzo, :length => 65, :omission => '')})
#        dati_destinatario << OpenStruct.new({:descrizione => [cliente.cap, cliente.citta].join(' ')})
#        dati_destinatario << OpenStruct.new({:descrizione => ['P.Iva', cliente.p_iva, 'C.F.', cliente.cod_fisc].join(' ')})
#
#        if configatron.attivita == Models::Azienda::ATTIVITA[:commercio]
#          if fattura.con_destinatario?
#            dati_destinatario << OpenStruct.new({:descrizione => "\nLuogo di destinazione"})
#            unless fattura.destinatario.blank?
#              dati_destinatario << OpenStruct.new({:descrizione => fattura.destinatario})
#            end
#            unless fattura.indirizzo_dest.blank?
#              dati_destinatario << OpenStruct.new({:descrizione => fattura.indirizzo_dest})
#            end
#            unless fattura.citta_dest.blank?
#              desc = [(fattura.cap_dest.blank? ? '' : fattura.cap_dest), fattura.citta_dest].join(' ')
#              dati_destinatario << OpenStruct.new({:descrizione => desc})
#            end
#          else
#            dati_destinatario << OpenStruct.new({:descrizione => ''})
#          end
#        end
#
#        report.add_table("Destinatario", dati_destinatario) do  |t|
#          t.add_column(:dati_destinatario, :descrizione)
#        end
#
#        report.add_field :fattura_luogo, (dati_azienda.citta + ' li,')
#        report.add_field :fattura_data, fattura.data_emissione.to_s(:italian_date)
#        if fattura.nota_di_credito?
#          report.add_field :fattura_desc, 'Nota di credito n.'
#        else
#          report.add_field :fattura_desc, 'Fattura n.'
#        end
#
#        report.add_field :fattura_num, fattura.num + '/' + fattura.data_emissione.to_s(:short_year)
#
#        if fattura.iva_diff?
#          report.add_field :iva_differita, 'Operazione con Iva ad esigibilità differita ex art. 7 D.L. 185/08'
#        else
#          report.add_field :iva_differita, ''
#        end
#
#      end
#
#      def render_body_odf(report, fattura=nil)
#        if configatron.attivita == Models::Azienda::ATTIVITA[:commercio]
#          report.add_table("Articoli", fattura.righe_fattura_cliente, :header => true, :skip_if_empty => true) do |t|
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
#          report.add_table("Articoli", fattura.righe_fattura_cliente, :header => true, :skip_if_empty => true) do |t|
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
#      def render_footer_odf(report, fattura=nil)
#        totali = []
#
#        dati_azienda = Models::Azienda.current.dati_azienda
#
#        # dati footer
#        riepilogo_importi = righe_fattura_cliente_panel.riepilogo_importi
#        aliquote = righe_fattura_cliente_panel.lku_aliquota.instance_hash
#        totale_imponibile = righe_fattura_cliente_panel.totale_imponibile
#        totale_iva = righe_fattura_cliente_panel.totale_iva
#        totale_fattura = righe_fattura_cliente_panel.totale_fattura
#        totale_ritenuta = righe_fattura_cliente_panel.totale_ritenuta
#
#        riepilogo_imposte = []
#        riepilogo_importi.each_pair do |key, importo|
#          riepilogo_imposte << OpenStruct.new({:codice => aliquote[key].codice,
#              :descrizione => aliquote[key].descrizione,
#              :imponibile => Helpers::ApplicationHelper.currency(importo),
#              :totale => Helpers::ApplicationHelper.currency(((importo * aliquote[key].percentuale) / 100))})
#        end
#
#        report.add_table("RiepilogoImposte", riepilogo_imposte, :header => true, :skip_if_empty => true) do  |t|
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
#            :importo => Helpers::ApplicationHelper.currency(totale_fattura)})
#
#        if ritenuta = fattura.ritenuta
#          totali << OpenStruct.new({:descrizione => "Ritenuta #{Helpers::ApplicationHelper.percentage(ritenuta.percentuale, 0)}",
#              :importo => Helpers::ApplicationHelper.currency(totale_ritenuta)})
#
#          totali << OpenStruct.new({:descrizione => "NETTO A PAGARE",
#              :importo => Helpers::ApplicationHelper.currency(totale_fattura - totale_ritenuta)})
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
#        if configatron.fatturazione.iva_per_cassa
#          report.add_field :iva_per_cassa, 'Operazione Iva per cassa ex art. 32-bis del D.L. 22 giugno 2012 n. 83'
#        else
#          report.add_field :iva_per_cassa, ''
#        end
#
#        dati_aggiuntivi = ''
#        dati_aggiuntivi << ['Tel.', dati_azienda.telefono, 'Fax', dati_azienda.fax].join(' ')
#        dati_aggiuntivi << ' E-mail ' + dati_azienda.e_mail unless dati_azienda.e_mail.blank?
#        dati_aggiuntivi << ' IBAN ' + dati_azienda.iban unless dati_azienda.iban.blank?
#
#        report.add_field :dati_aggiuntivi, dati_aggiuntivi
#
#        report.add_field :cap_soc, Helpers::ApplicationHelper.currency(dati_azienda.cap_soc)
#        report.add_field :reg_imp_citta, dati_azienda.reg_imprese
#        report.add_field :reg_imp_num, dati_azienda.num_reg_imprese
#        report.add_field :rea_num, dati_azienda.num_rea
#
#      end

    end
  end
end
