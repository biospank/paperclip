# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/fornitori_dialog'
require 'app/views/dialog/ordini_dialog'
require 'app/views/dialog/prodotti_dialog'
require 'app/views/magazzino/righe_ordine_panel'
#require 'odf-report'
#require 'ostruct'

module Views
  module Magazzino
    module OrdinePanel
      include Views::Base::Panel
      include Helpers::MVCHelper
#      include Helpers::ODF::Report
      include Helpers::Wk::HtmlToPdf
      include ERB::Util
      
      def ui(container=nil)
        
        model :fornitore => {:attrs => [:denominazione, :p_iva]},
          :ordine => {:attrs => [:num, 
                                  :data_emissione]}
        
        controller :magazzino

        logger.debug('initializing OrdinePanel...')
        xrc = Xrc.instance()
        # Fattura fornitore
        
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_num', self, :extends => TextField)
        xrc.find('txt_data_emissione', self, :extends => DateField) do |field|
          field.evt_char { |evt| txt_data_emissione_keypress(evt) }
        end

        xrc.find('btn_fornitore', self)
        xrc.find('btn_variazione', self)
        xrc.find('btn_stampa', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_pulisci', self)

        map_events(self)

        xrc.find('RIGHE_ORDINE_PANEL', container, 
          :extends => Views::Magazzino::RigheOrdinePanel, 
          :force_parent => self)

        righe_ordine_panel.ui()

        subscribe(:evt_dettaglio_ordine) do |ordine|
          reset_panel()
          self.ordine = ordine
          self.fornitore = self.ordine.fornitore
          transfer_fornitore_to_view()
          transfer_ordine_to_view()
          righe_ordine_panel.display_righe_ordine(self.ordine)

          reset_ordine_command_state()
          righe_ordine_panel.lku_prodotto.activate()

        end

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_stampa_ordini) do |ordini|
          stampa_ordini(ordini)
        end

      end

      # viene chiamato al cambio folder
      def init_panel()
        # imposto la data di oggi
        txt_data_emissione.view_data = Date.today if txt_data_emissione.view_data.blank?

        reset_ordine_command_state()

        righe_ordine_panel.init_panel()
        
        txt_num.enabled? ? txt_num.activate() : righe_ordine_panel.txt_importo.activate()
      end
      
      # Resetta il pannello reinizializzando il modello
      def reset_panel()
        begin
          reset_fornitore()
          reset_ordine()
          
          # imposto la data di oggi
          txt_data_emissione.view_data = Date.today

          enable_widgets [
            txt_num,
            txt_data_emissione
          ]

          reset_ordine_command_state()

          righe_ordine_panel.reset_panel()

          txt_num.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi
      
      def txt_data_emissione_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              txt_num.activate()
            else
              righe_ordine_panel.lku_prodotto.activate()
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_fornitore_click(evt)
        begin
          Wx::BusyCursor.busy() do
            fornitori_dlg = Views::Dialog::FornitoriDialog.new(self)
            fornitori_dlg.center_on_screen(Wx::BOTH)
            answer = fornitori_dlg.show_modal()
            if answer == Wx::ID_OK
              reset_panel()
              self.fornitore = ctrl.load_fornitore(fornitori_dlg.selected)
              self.ordine.fornitore = self.fornitore
              transfer_fornitore_to_view()
              txt_num.activate()
            elsif answer == fornitori_dlg.btn_nuovo.get_id
              evt_new = Views::Base::CustomEvent::NewEvent.new(:fornitore, [Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW, Helpers::MagazzinoHelper::WXBRA_ORDINE_FOLDER])
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
            # se esiste ricerca solo le occorrenze associate ad un fornitore
            transfer_fornitore_from_view()
            ordini_dlg = Views::Dialog::OrdiniDialog.new(self)
            ordini_dlg.center_on_screen(Wx::BOTH)
            if ordini_dlg.show_modal() == Wx::ID_OK
              self.ordine = ctrl.load_ordine(ordini_dlg.selected)
              self.fornitore = self.ordine.fornitore
              transfer_fornitore_to_view()
              transfer_ordine_to_view()
              righe_ordine_panel.display_righe_ordine(self.ordine)

              disable_widgets [
                txt_num,
                txt_data_emissione
              ]

              reset_ordine_command_state()
              righe_ordine_panel.lku_prodotto.activate()

            else
              logger.debug("You pressed Cancel")
            end

            ordini_dlg.destroy()
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
              if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
                transfer_ordine_from_view()
                if fornitore?
                  if self.ordine.valid?
                    ctrl.save_ordine()

                    #notify(:evt_magazzino_fornitori_changed)

                    Wx::message_box('Salvataggio avvenuto correttamente',
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    res_stampa = Wx::message_box("Vuoi stampare l'ordine?",
                      'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                    if res_stampa == Wx::YES
                      btn_stampa_click(nil)
                    end

                    reset_panel()
                  else
                    Wx::message_box(self.ordine.error_msg,
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)

                    focus_ordine_error_field()

                  end
                end
              else
                Wx::message_box('Utente non autorizzato.',
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
            if can? :write, Helpers::ApplicationHelper::Modulo::MAGAZZINO
              res = Wx::message_box("Confermi la cancellazione dell'ordine e tutte le righe collegate?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              Wx::BusyCursor.busy() do
                if res == Wx::YES
                  ctrl.delete_ordine()
                  #notify(:evt_magazzino_fornitori_changed)
                  reset_panel()
                end
              end
            else
              Wx::message_box('Utente non autorizzato.',
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
      
      def reset_ordine_command_state()
        if ordine.new_record?
          enable_widgets [btn_salva,btn_fornitore,btn_variazione]
          disable_widgets [btn_elimina]
        else
          if ordine.caricato_in_magazzino?
            disable_widgets [btn_salva,btn_elimina,txt_num,txt_data_emissione,btn_fornitore,btn_variazione]
          else
            enable_widgets [btn_salva,btn_elimina,txt_num,txt_data_emissione,btn_fornitore,btn_variazione]
          end
        end
      end

      def fornitore?
        if self.fornitore.new_record?
          Wx::message_box('Selezionare un fornitore',
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
            
          btn_fornitore.set_focus()
          return false
        else
          return true
        end

      end

      def btn_stampa_click(evt)
        if self.ordine.new_record?
          Wx::message_box("Per avviare il processo di stampa è necessario salvare l'ordine.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)
        else
          Wx::BusyCursor.busy() do

            dati_azienda = Models::Azienda.current.dati_azienda
            ordine = Models::Ordine.find(self.ordine.id, :include => [:fornitore, :righe_ordine])

            generate(:ordine,
              :margin_top => 90,
              :margin_bottom => 25,
              :dati_azienda => dati_azienda,
              :ordine => ordine
            )

          end
        end
      end

      def stampa_ordini(ordini)
        Wx::BusyCursor.busy() do

          dati_azienda = Models::Azienda.current.dati_azienda
          ordini.each do |o|
            ordine = Models::Ordine.find(o, :include => [:fornitore, :righe_ordine])

            reset_panel()

            self.ordine = ordine
            self.fornitore = self.ordine.fornitore
            transfer_fornitore_to_view()
            transfer_ordine_to_view()
            righe_ordine_panel.display_righe_ordine(self.ordine)

            generate(o,
              :margin_top => 90,
              :margin_bottom => 65,
              :dati_azienda => dati_azienda,
              :ordine => ordine,
              :preview => false
            )

          end

          reset_panel()

          merge_all(ordini,
            :output => :ordini
          )

        end
      end

      def render_header(opts={})
        dati_azienda = opts[:dati_azienda]
        ordine = opts[:ordine]

        unless dati_azienda.logo.blank?
          logo_path = File.join(Helpers::ApplicationHelper::WXBRA_IMAGES_PATH, ('logo.' << dati_azienda.logo_tipo))
          open(logo_path, "wb") {|io| io.write(dati_azienda.logo) }
        end

        header.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::OrdineHeaderTemplatePath)
          ).result(binding)
        )


      end

      def render_body(opts={})
        dati_azienda = opts[:dati_azienda]
        ordine = opts[:ordine]

        body.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::OrdineBodyTemplatePath)
          ).result(binding)
        )

      end

      def render_footer(opts={})
        dati_azienda = opts[:dati_azienda]
        ordine = opts[:ordine]

        footer.write(
          ERB.new(
            IO.read(Helpers::MagazzinoHelper::OrdineFooterTemplatePath)
          ).result(binding)
        )

      end

#      def btn_stampa_click(evt)
#        if self.ordine.new_record?
#          Wx::message_box("Per avviare il processo di stampa è necessario salvare l'ordine.",
#            'Info',
#            Wx::OK | Wx::ICON_INFORMATION, self)
#        else
#          Wx::BusyCursor.busy() do
#
#            dati_azienda = Models::Azienda.current.dati_azienda
#            ordine = Models::Ordine.find(self.ordine.id, :include => [:fornitore, :righe_ordine])
#
#            if dati_azienda.logo.blank?
#              template = Helpers::MagazzinoHelper::OrdineTemplatePath
#            else
#              template = Helpers::MagazzinoHelper::OrdineTemplateLogoPath
#            end
#
#            generate(template, ordine)
#
#          end
#        end
#      end
#
#      def render_header(report, ordine=nil)
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
#        fornitore = ordine.fornitore
#
#        report.add_field :destinatario, Helpers::ApplicationHelper.truncate(fornitore.denominazione, :length => 65, :omission => '')
#
#        dati_destinatario = []
#
#        #dati_destinatario << OpenStruct.new({:descrizione => cliente.denominazione})
#        dati_destinatario << OpenStruct.new({:descrizione => Helpers::ApplicationHelper.truncate(fornitore.indirizzo, :length => 65, :omission => '')})
#        dati_destinatario << OpenStruct.new({:descrizione => [fornitore.cap, fornitore.citta].join(' ')})
#        dati_destinatario << OpenStruct.new({:descrizione => ['P.Iva', fornitore.p_iva, 'C.F.', fornitore.cod_fisc].join(' ')})
#
#        report.add_table("Destinatario", dati_destinatario) do  |t|
#          t.add_column(:dati_destinatario, :descrizione)
#        end
#
#        report.add_field :ordine_luogo, (dati_azienda.citta + ' li,')
#        report.add_field :ordine_data, ordine.data_emissione.to_s(:italian_date)
#        report.add_field :ordine_desc, 'Ordine n.'
#
#        report.add_field :ordine_num, ordine.num + '/' + ordine.data_emissione.to_s(:short_year)
#
#      end
#
#      def render_body(report, ordine=nil)
#        report.add_table("Articoli", ordine.righe_ordine, :header=>true) do |t|
#          t.add_column(:descrizione) {|row| row.prodotto.descrizione}
#          t.add_column(:qta)
#        end
#      end
#
#      def render_footer(report, ordine=nil)
#        dati_azienda = Models::Azienda.current.dati_azienda
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
#        unless dati_azienda.e_mail.blank?
#          dati_aggiuntivi << ' E-mail ' + dati_azienda.e_mail
#        end
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