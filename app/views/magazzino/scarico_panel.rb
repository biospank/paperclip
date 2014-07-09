# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/clienti_dialog'
require 'app/views/dialog/prodotti_dialog'
require 'app/views/magazzino/righe_scarico_panel'

module Views
  module Magazzino
    module ScaricoPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      def ui(container=nil)

        model :cliente => {:attrs => [:denominazione, :p_iva]},
          :fattura_cliente_fatturazione => {:attrs => [:num, :data_emissione], :alias => :fattura_cliente}

        controller :magazzino

        logger.debug('initializing ScaricoPanel...')
        xrc = Xrc.instance()
        # Fattura cliente

        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_num', self, :extends => TextField)
        xrc.find('txt_data_emissione', self, :extends => DateField)

        xrc.find('chce_magazzino', self, :extends => ChoiceField)

        subscribe(:evt_dettaglio_magazzino_changed) do |data|
          chce_magazzino.load_data(data,
                  :label => :nome,
                  :if => lambda {|magazzino| magazzino.attivo? },
                  :select => :default,
                  :default => (data.detect { |magazzino| magazzino.predefinito? }) || data.first)

        end

        xrc.find('btn_cliente', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_pulisci', self)

        map_events(self)

        xrc.find('RIGHE_SCARICO_PANEL', container,
          :extends => Views::Magazzino::RigheScaricoPanel,
          :force_parent => self)

        righe_scarico_panel.ui()

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

      end

      # viene chiamato al cambio folder
      def init_panel()
        update_fattura_ui()
        righe_scarico_panel.init_panel()
      end

      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_cliente()
          reset_fattura_cliente()

          update_fattura_ui()

          righe_scarico_panel.reset_panel()

          righe_scarico_panel.lku_bar_code.activate()

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
              self.cliente = ctrl.load_cliente(clienti_dlg.selected)
              transfer_cliente_to_view()
              update_fattura_ui()
            elsif answer == clienti_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:cliente, [Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW, Helpers::MagazzinoHelper::WXBRA_SCARICO_FOLDER])
              # This sends the event for processing by listeners
              process_event(evt_new)
            else
              logger.debug("You pressed Cancel")
            end

            clienti_dlg.destroy()
            righe_scarico_panel.lku_bar_code.activate()
          end
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
                if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
                  if righe_scarico_panel.lstrep_righe_scarico.get_item_count() > 0
                    transfer_cliente_from_view()
                    transfer_fattura_cliente_from_view()
                    if fattura_cliente_valida?
                      fattura = ctrl.save_movimenti_scarico(!self.cliente.denominazione.blank?)

                      anni_contabili_movimenti = ctrl.load_anni_contabili(Models::Movimento, 'data')
                      notify(:evt_anni_contabili_movimenti_changed, anni_contabili_movimenti)

                      unless self.cliente.denominazione.blank?
                        res_stampa = Wx::message_box("Salvataggio avvenuto correttamente: fattura n. #{fattura.num} del #{fattura.data_emissione.to_s(:italian_date)}\nVuoi stampare la fattura?",
                         'Domanda',
                         Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                        if res_stampa == Wx::YES
                          notify(:evt_stampa_fattura, fattura)
                        end
                        righe_scarico_panel.lku_bar_code.activate()
                      else
                        Wx::message_box('Salvataggio avvenuto correttamente',
                          'Info',
                          Wx::OK | Wx::ICON_INFORMATION, self)
                      end
                      reset_panel()
                      righe_scarico_panel.lku_bar_code.activate()
                    else
                      msg = self.fattura_cliente.error_msg
                      msg << " (da fatturazione o scadenzario)" if msg =~ /fattura/
                      Wx::message_box(msg,
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      focus_fattura_cliente_error_field()

                    end
                  else
                    Wx::message_box("Leggere il codice a barre del prodotto oppure\npremere F5 per la ricerca manuale.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                    righe_scarico_panel.lku_bar_code.activate()
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

      def btn_pulisci_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end

      def stampa_fattura()

      end

      def btn_stampa_click(evt)
        Wx::BusyCursor.busy() do
          template = Helpers::MagazzinoHelper::ReportGiacenzeTemplatePath
          generate(template)
        end
      end

      def render_header(report, whatever=nil)
        dati_azienda = Models::Azienda.current.dati_azienda

        report.add_field :denominazione, dati_azienda.denominazione
        report.add_field :intestazione, ["Report Giacenze Magazzino", (filtro.al.blank? ? '' : "al #{filtro.al.to_s(:italian_date)}")].join(' ')
      end

      def render_body(report, whatever=nil)
        report.add_table("Report", self.result_set_lstrep_giacenze, :header=> true) do |t|
          t.add_column(:codice)
          t.add_column(:descrizione)
          t.add_column(:qta)
          t.add_column(:prezzo_unitario) {|prodotto| Helpers::ApplicationHelper.currency(prodotto.prezzo_acquisto)}
          t.add_column(:totale) {|prodotto| Helpers::ApplicationHelper.currency((prodotto.qta.to_i * prodotto.prezzo_acquisto.to_f))}
        end
      end

      def render_footer(report, whatever=nil)
        report.add_field :tot_magazzino, self.lbl_totale_magazzino.label
      end

      def update_fattura_ui()
        if cliente.denominazione.blank?
          disable_widgets [
            txt_num,
            txt_data_emissione
          ]

          # calcolo il progressivo
          txt_num.view_data = nil

          # imposto la data di oggi
          txt_data_emissione.view_data = nil

        else
          enable_widgets [
            txt_num,
            txt_data_emissione
          ]
          # calcolo il progressivo
          txt_num.view_data = Models::ProgressivoFatturaCliente.next_sequence(Date.today.year) if txt_num.view_data.blank?
          # imposto la data di oggi
          txt_data_emissione.view_data = Date.today if txt_data_emissione.view_data.blank?

        end

        def fattura_cliente_valida?
          if self.cliente.denominazione.blank?
            return true
          else
            if self.fattura_cliente.valid?
              return true
            else
              return false
            end
          end
        end

      end
    end
  end
end
