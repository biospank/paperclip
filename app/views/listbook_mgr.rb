# encoding: utf-8

require 'app/views/anagrafica/anagrafica_notebook_mgr'
require 'app/views/fatturazione/fatturazione_notebook_mgr'
require 'app/views/scadenzario/scadenzario_notebook_mgr'
require 'app/views/prima_nota/prima_nota_notebook_mgr'
require 'app/views/magazzino/magazzino_notebook_mgr'
require 'app/views/configurazione/configurazione_notebook_mgr'
require 'app/views/dialog/scadenze_dialog'

module Views
  module ListbookMgr
    include Views::Base::View
    include Helpers::MVCHelper

    attr_accessor :timer_scadenze, :main_frame

    def ui(parent)
      @main_frame = parent

      controller :base

      logger.debug('initializing ListbookMgr...')

      img_list = Wx::ImageList.new(48, 48)
      img_list << Helpers::ImageHelper.make_bitmap('ana.png')
      img_list << Wx::Bitmap.new(Helpers::ImageHelper.make_image('ana.png').convert_to_greyscale())
      img_list << Helpers::ImageHelper.make_bitmap('fatt.png')
      img_list << Wx::Bitmap.new(Helpers::ImageHelper.make_image('fatt.png').convert_to_greyscale())
      img_list << Helpers::ImageHelper.make_bitmap('scad.png')
      img_list << Wx::Bitmap.new(Helpers::ImageHelper.make_image('scad.png').convert_to_greyscale())
      img_list << Helpers::ImageHelper.make_bitmap('pn.png')
      img_list << Wx::Bitmap.new(Helpers::ImageHelper.make_image('pn.png').convert_to_greyscale())
      img_list << Helpers::ImageHelper.make_bitmap('mag.png')
      img_list << Wx::Bitmap.new(Helpers::ImageHelper.make_image('mag.png').convert_to_greyscale())
      img_list << Helpers::ImageHelper.make_bitmap('conf.png')
      img_list << Wx::Bitmap.new(Helpers::ImageHelper.make_image('conf.png').convert_to_greyscale())

      self.set_image_list(img_list)

      self.set_page_image(Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW, 1)
      self.set_page_image(Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW, 3)
      self.set_page_image(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW, 5)
      self.set_page_image(Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW, 7)
      if configatron.bilancio.attivo
        self.set_page_text(3, 'Partita Doppia')
      else
        self.set_page_text(3, 'Prima Nota')
      end
      self.set_page_image(Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW, 9)
      self.set_page_image(Helpers::ApplicationHelper::WXBRA_CONFIGURAZIONE_VIEW, 11)

      setup_listeners()
      xrc = Helpers::WxHelper::Xrc.instance()
      xrc.find('ANAGRAFICA_NOTEBOOK_MGR', self, :extends => Views::Anagrafica::AnagraficaNotebookMgr)
      anagrafica_notebook_mgr.ui()
      anagrafica_notebook_mgr.set_selection(Helpers::AnagraficaHelper::WXBRA_ANAGRAFICA_FOLDER)
      xrc.find('FATTURAZIONE_NOTEBOOK_MGR', self, :extends => Views::Fatturazione::FatturazioneNotebookMgr)
      fatturazione_notebook_mgr.ui()
      fatturazione_notebook_mgr.set_selection(Helpers::FatturazioneHelper::WXBRA_NOTA_SPESE_FOLDER)
      xrc.find('SCADENZARIO_NOTEBOOK_MGR', self, :extends => Views::Scadenzario::ScadenzarioNotebookMgr)
      scadenzario_notebook_mgr.ui()
      scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
      xrc.find('PRIMA_NOTA_NOTEBOOK_MGR', self, :extends => Views::PrimaNota::PrimaNotaNotebookMgr)
      prima_nota_notebook_mgr.ui()
      prima_nota_notebook_mgr.set_selection(Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
      xrc.find('MAGAZZINO_NOTEBOOK_MGR', self, :extends => Views::Magazzino::MagazzinoNotebookMgr)
      magazzino_notebook_mgr.ui()
      magazzino_notebook_mgr.set_selection(Helpers::MagazzinoHelper::WXBRA_SCARICO_FOLDER)
      xrc.find('CONFIGURAZIONE_NOTEBOOK_MGR', self, :extends => Views::Configurazione::ConfigurazioneNotebookMgr)
      configurazione_notebook_mgr.ui()
      configurazione_notebook_mgr.set_selection(Helpers::ConfigurazioneHelper::WXBRA_AZIENDA_FOLDER)

      map_events(self)

      evt_listbook_page_changing(self)    { |evt| listbook_page_changing(evt) }
      evt_listbook_page_changed(self)    { |evt| listbook_page_changed(evt) }

      evt_azienda_updated do | evt |
        Models::Azienda.current.dati_azienda.reload
        notify(:evt_azienda_updated)
      end

      evt_cliente_changed do | evt |
        notify(:evt_cliente_changed, evt.result_set)
      end

      evt_back do | evt |
        view, folder = self.source
        if view && folder
          set_selection(view)
          case view
          when Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW
            anagrafica_notebook_mgr.set_selection(folder)
          when Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW
            fatturazione_notebook_mgr.set_selection(folder)
          when Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW
            scadenzario_notebook_mgr.set_selection(folder)
          when Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW
            prima_nota_notebook_mgr.set_selection(folder)
          when Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW
            magazzino_notebook_mgr.set_selection(folder)
          when Helpers::ApplicationHelper::WXBRA_CONFIGURAZIONE_VIEW
            configurazione_notebook_mgr.set_selection(folder)
          end
        end

        self.source = nil
      end

      evt_new do | evt |
        auth_message = 'Attenzione! Utente non autorizzato o modulo non abilitato.'
        self.source = evt.data[:caller]
        case evt.data[:subject]
        when :cliente
          if can? :read, Helpers::ApplicationHelper::Modulo::ANAGRAFICA
            set_selection(Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW)
            anagrafica_notebook_mgr.set_selection(Helpers::AnagraficaHelper::WXBRA_ANAGRAFICA_FOLDER)
            notify(:evt_new_cliente)
          else
            main_frame.set_status_text(auth_message)
          end
        when :fornitore
          if can? :read, Helpers::ApplicationHelper::Modulo::ANAGRAFICA
            set_selection(Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW)
            anagrafica_notebook_mgr.set_selection(Helpers::AnagraficaHelper::WXBRA_ANAGRAFICA_FOLDER)
            notify(:evt_new_fornitore)
          else
            main_frame.set_status_text(auth_message)
          end
        when :aliquota
          if can? :read, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
            set_selection(Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW)
            fatturazione_notebook_mgr.set_selection(Helpers::FatturazioneHelper::WXBRA_IMPOSTAZIONI_FOLDER)
            notify(:evt_new_aliquota)
          else
            main_frame.set_status_text(auth_message)
          end
        when :ritenuta
          if can? :read, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
            set_selection(Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW)
            fatturazione_notebook_mgr.set_selection(Helpers::FatturazioneHelper::WXBRA_IMPOSTAZIONI_FOLDER)
            notify(:evt_new_ritenuta)
          else
            main_frame.set_status_text(auth_message)
          end
        when :incasso_ricorrente
          if can? :read, Helpers::ApplicationHelper::Modulo::FATTURAZIONE
            set_selection(Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW)
            fatturazione_notebook_mgr.set_selection(Helpers::FatturazioneHelper::WXBRA_IMPOSTAZIONI_FOLDER)
            notify(:evt_new_incasso_ricorrente)
          else
            main_frame.set_status_text(auth_message)
          end
        when :tipo_incasso
          if can? :read, Helpers::ApplicationHelper::Modulo::SCADENZARIO
            set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
            scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
            notify(:evt_new_tipo_incasso)
          else
            main_frame.set_status_text(auth_message)
          end
        when :tipo_pagamento
          if can? :read, Helpers::ApplicationHelper::Modulo::SCADENZARIO
            set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
            scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
            notify(:evt_new_tipo_pagamento)
          else
            main_frame.set_status_text(auth_message)
          end
        when :causale
          if can? :read, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
            set_selection(Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW)
            prima_nota_notebook_mgr.set_selection(Helpers::PrimaNotaHelper::WXBRA_CAUSALI_FOLDER)
            notify(:evt_new_causale)
          else
            main_frame.set_status_text(auth_message)
          end
        when :pdc
          if can? :read, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
            set_selection(Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW)
            prima_nota_notebook_mgr.set_selection(Helpers::PrimaNotaHelper::WXBRA_PDC_FOLDER)
            notify(:evt_new_pdc)
          else
            main_frame.set_status_text(auth_message)
          end
        when :norma
          if can? :read, Helpers::ApplicationHelper::Modulo::SCADENZARIO
            set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
            scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_IMPOSTAZIONI_SCADENZARIO_FOLDER)
            notify(:evt_new_norma)
          else
            main_frame.set_status_text(auth_message)
          end
        when :prodotto
          if can? :read, Helpers::ApplicationHelper::Modulo::MAGAZZINO
            set_selection(Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW)
            magazzino_notebook_mgr.set_selection(Helpers::MagazzinoHelper::WXBRA_IMPOSTAZIONI_FOLDER)
            notify(:evt_new_prodotto)
          else
            main_frame.set_status_text(auth_message)
          end
        when :banca
          if can? :read, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
            set_selection(Helpers::ApplicationHelper::WXBRA_CONFIGURAZIONE_VIEW)
            configurazione_notebook_mgr.set_selection(Helpers::ConfigurazioneHelper::WXBRA_AZIENDA_FOLDER)
            notify(:evt_new_banca)
          else
            main_frame.set_status_text(auth_message)
          end
        end
      end

      evt_fornitore_changed do | evt |
        notify(:evt_fornitore_changed, evt.result_set)
      end

      evt_aliquota_changed do | evt |
        notify(:evt_aliquota_changed, evt.result_set)
      end

      evt_norma_changed do | evt |
        notify(:evt_norma_changed, evt.result_set)
      end

      evt_pdc_changed do | evt |
        notify(:evt_pdc_changed, evt.result_set)
      end

      evt_categoria_pdc_changed do | evt |
        notify(:evt_categoria_pdc_changed, evt.result_set)
      end

      evt_ritenuta_changed do | evt |
        notify(:evt_ritenuta_changed, evt.result_set)
      end

      evt_causale_changed do | evt |
        notify(:evt_causale_changed, evt.result_set)
      end

      evt_banca_changed do | evt |
        notify(:evt_banca_changed, evt.result_set)
      end

      evt_tipo_pagamento_cliente_changed do | evt |
        notify(:evt_tipo_pagamento_cliente_changed, evt.result_set)
      end

      evt_tipo_pagamento_fornitore_changed do | evt |
        notify(:evt_tipo_pagamento_fornitore_changed, evt.result_set)
      end

      evt_scadenza_in_sospeso do | evt |
        begin
          unless Models::Utente.system?
            if can? :read, Helpers::ApplicationHelper::Modulo::SCADENZARIO
              logger.debug("timer running...")
              # carico i pagamenti e gli incassi in sospeso
              ctrl.carica_movimenti_in_sospeso() if evt.reload?
              ctrl.locked = false
              if ctrl.movimenti_in_sospeso?
                # alla prima notifica timer_scadenze non e' ancora inizializzato
                timer_scadenze.stop if timer_scadenze
                scadenze_dlg = Views::Dialog::ScadenzeDialog.new(self)
                scadenze_dlg.center_on_screen(Wx::BOTH)
                #ctrl.waiting = true
                answer = scadenze_dlg.show_modal()
                case answer
                when Wx::ID_OK
                  scadenza = scadenze_dlg.selected
                  if scadenza.is_a? Models::PagamentoFatturaCliente
                    set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
                    scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
                    ctrl.locked = true
                    notify(:evt_dettaglio_incasso, scadenza)
                  else
                    set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
                    scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
                    ctrl.locked = true
                    notify(:evt_dettaglio_pagamento, scadenza)
                  end
                when Wx::ID_CANCEL
                  # alla prima notifica timer_scadenze non e' ancora inizializzato
                  timer_scadenze.start if timer_scadenze
                  ctrl.locked = false
                when Wx::ID_EXIT
                  # alla prima notifica timer_scadenze non e' ancora inizializzato
                  timer_scadenze.start if timer_scadenze
                  # da abilitare se si vuole forzare il completamento dei movimenti in sospeso alla login
                  #evt_f_exit = Views::Base::CustomEvent::ForceExitEvent.new()
                  #process_event(evt_f_exit)
                end

                scadenze_dlg.destroy()
                #ctrl.waiting = false

              end
            end
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_incasso do | evt |
        begin
          incasso = evt.incasso
          set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
          scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
          notify(:evt_dettaglio_incasso, incasso)
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_scrittura do | evt |
        begin
          scrittura = evt.scrittura
          set_selection(Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW)
          prima_nota_notebook_mgr.set_selection(Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
          notify(:evt_dettaglio_scrittura, scrittura)
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_pagamento do | evt |
        begin
          pagamento = evt.pagamento
          set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
          scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
          notify(:evt_dettaglio_pagamento, pagamento)
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_corrispettivo do | evt |
        begin
          corrispettivo = evt.corrispettivo
          set_selection(Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW)
          fatturazione_notebook_mgr.set_selection(Helpers::FatturazioneHelper::WXBRA_CORRISPETTIVI_FOLDER)
          notify(:evt_dettaglio_corrispettivo, corrispettivo)
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_fattura_scadenzario do | evt |
        begin
          fattura = evt.fattura
          if fattura.is_a? Models::FatturaClienteScadenzario
            set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
            scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_CLIENTI_FOLDER)
            notify(:evt_dettaglio_fattura_cliente_scadenzario, fattura)
          else
            set_selection(Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW)
            scadenzario_notebook_mgr.set_selection(Helpers::ScadenzarioHelper::WXBRA_SCADENZARIO_FORNITORI_FOLDER)
            notify(:evt_dettaglio_fattura_fornitore_scadenzario, fattura)
          end
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_fattura_fatturazione do | evt |
        begin
          fattura = evt.fattura
          set_selection(Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW)
          fatturazione_notebook_mgr.set_selection(Helpers::FatturazioneHelper::WXBRA_FATTURA_FOLDER)
          notify(:evt_dettaglio_fattura_cliente_fatturazione, fattura)
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_nota_spese do | evt |
        begin
          nota_spese = evt.nota_spese
          set_selection(Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW)
          fatturazione_notebook_mgr.set_selection(Helpers::FatturazioneHelper::WXBRA_NOTA_SPESE_FOLDER)
          notify(:evt_dettaglio_nota_spese, nota_spese)
        rescue Exception => e
          log_error(self, e)
        end
      end

      evt_dettaglio_ordine do | evt |
        begin
          ordine = evt.ordine
          set_selection(Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW)
          magazzino_notebook_mgr.set_selection(Helpers::MagazzinoHelper::WXBRA_ORDINE_FOLDER)
          notify(:evt_dettaglio_ordine, ordine)
        rescue Exception => e
          log_error(self, e)
        end
      end

      # carico tutti i dati che non dipendono
      # dall'azienda selezionata

      # carico le ritenute
      ritenute = ctrl.search_ritenute()
      notify(:evt_ritenuta_changed, ritenute)

      # carico le aliquote
      aliquote = ctrl.search_aliquote()
      notify(:evt_aliquota_changed, aliquote)

      # carico i codici norma
      codici_norma = ctrl.search_norma()
      notify(:evt_norma_changed, codici_norma)

      # carico le causali
      causali = ctrl.search_causali()
      notify(:evt_causale_changed, causali)

      # carico il piano dei conti
      pdc = ctrl.search_categorie_pdc()
      notify(:evt_categoria_pdc_changed, pdc)

      # carico il piano dei conti
      pdc = ctrl.search_pdc()
      notify(:evt_pdc_changed, pdc)

      # carico i tipi pagamento cliente
      tipi_pagamento_cliente = ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::CLIENTI)
      notify(:evt_tipo_pagamento_cliente_changed, tipi_pagamento_cliente)

      # carico i tipi pagamento fornitore
      tipi_pagamento_fornitore = ctrl.search_tipi_pagamento(Helpers::AnagraficaHelper::FORNITORI)
      notify(:evt_tipo_pagamento_fornitore_changed, tipi_pagamento_fornitore)

      # abilito/disabilito i campi relativi al bilancio
      notify(:evt_bilancio_attivo, configatron.bilancio.attivo)

      # abilito/disabilito i campi relativi alla liquidazione iva
      notify(:evt_liquidazioni_attivo, configatron.liquidazioni.attivo)

    end

    # viene chiamato dopo la login
    def init_folders()
      load_dependent_data()
    end

    # chiamato al cambio azienda
    def reset_folders()
      Wx::BusyCursor.busy() do
        notify(:evt_azienda_changed)
        load_dependent_data()
      end
    end

    # viene chiamato dopo la login e al cambio azienda
    def load_dependent_data(check_sospesi=true)
      # Durante l'inizializzazione vengono considerate tutte
      # le ricerche collegate con l'azienda che e' stata scelta
      # in fase di login

      # carico gli anni contabili delle note spese
      anni_contabili_ns = ctrl.load_anni_contabili(Models::NotaSpese)
      notify(:evt_anni_contabili_ns_changed, anni_contabili_ns)

      # carico gli anni contabili delle fatture clienti
      anni_contabili_fatture_clienti = ctrl.load_anni_contabili(Models::FatturaCliente)
      notify(:evt_anni_contabili_fattura_cliente_changed, anni_contabili_fatture_clienti)

      # carico gli anni contabili delle fatture fornitori
      anni_contabili_fatture_fornitori = ctrl.load_anni_contabili(Models::FatturaFornitore)
      notify(:evt_anni_contabili_fattura_fornitore_changed, anni_contabili_fatture_fornitori)

      # carico gli anni contabili delle scritture
      anni_contabili_scritture = ctrl.load_anni_contabili(Models::Scrittura, :data_operazione)
      notify(:evt_anni_contabili_scrittura_changed, anni_contabili_scritture)

      # carico gli anni contabili dei documenti di trasporto
      anni_contabili_ddt = ctrl.load_anni_contabili(Models::Ddt)
      notify(:evt_anni_contabili_ddt_changed, anni_contabili_ddt)

      # carico gli anni contabili degli ordini
      anni_contabili_ordini = ctrl.load_anni_contabili(Models::Ordine)
      notify(:evt_anni_contabili_ordine_changed, anni_contabili_ordini)

      # carico gli anni contabili dei movimenti di magazzino
      anni_contabili_movimenti = ctrl.load_anni_contabili(Models::Movimento, 'data')
      notify(:evt_anni_contabili_movimenti_changed, anni_contabili_movimenti)

      # carico gli anni contabili dei corrispettivi
      anni_contabili_corrispettivi = ctrl.load_anni_contabili(Models::Corrispettivo, 'data')
      notify(:evt_anni_contabili_corrispettivi_changed, anni_contabili_corrispettivi)

      # carico i corrispettivi del mese corrente
      notify(:evt_load_corrispettivi)

      # PROGRESSIVI
      #
      # carico gli anni contabili dei progressivi nota spese
      progressivi_ns = ctrl.load_anni_contabili_progressivi(Models::ProgressivoNotaSpese)
      notify(:evt_progressivo_ns, progressivi_ns)

      # carico gli anni contabili dei progressivi fattura
      progressivi_fattura = ctrl.load_anni_contabili_progressivi(Models::ProgressivoFatturaCliente)
      notify(:evt_progressivo_fattura, progressivi_fattura)

      # carico gli anni contabili dei progressivi nota di credito
      progressivi_nc = ctrl.load_anni_contabili_progressivi(Models::ProgressivoNc)
      notify(:evt_progressivo_nc, progressivi_nc)

      # carico gli anni contabili dei progressivi ddt
      progressivi_ddt = ctrl.load_anni_contabili_progressivi(Models::ProgressivoDdt)
      notify(:evt_progressivo_ddt, progressivi_ddt)

      # carico i clienti
      clienti = ctrl.search_clienti()
      notify(:evt_cliente_changed, clienti)

      # carico i fornitori
      fornitori = ctrl.search_fornitori()
      notify(:evt_fornitore_changed, fornitori)

      # carico i magazzini
      magazzini = ctrl.search_magazzini()
      notify(:evt_dettaglio_magazzino_changed, magazzini)

      # carico i prodotti
      prodotti = ctrl.search_prodotti()
      notify(:evt_prodotto_changed, prodotti)

      # carico le banche
      banche = ctrl.search_banche()
      notify(:evt_banca_changed, banche)

      # carico le scritture
      scritture = ctrl.search_scritture()
      notify(:evt_prima_nota_changed, scritture)

      # carico i moduli azienda
      moduli_azienda = ctrl.load_moduli_azienda()
      notify(:evt_moduli_azienda_changed, moduli_azienda)


      # lancio l'evento per il controllo delle scadenze
      # This sends the event for processing by listeners
      process_event(Views::Base::CustomEvent::ScadenzaInSospesoEvent.new()) if check_sospesi

      # ogni n minuti (60000 = 1 minuto) verifica i movimenti in sospeso
      self.timer_scadenze = Wx::Timer.every(300000) do
        process_event(Views::Base::CustomEvent::ScadenzaInSospesoEvent.new()) unless ctrl.locked?
      end
    end

    def listbook_page_changing(evt)
      if ctrl.locked?
#        Wx::message_box("Completare la chiusura dei movimenti in sospeso.",
#          'Info',
#          Wx::OK | Wx::ICON_INFORMATION, self)
#
        evt.veto()
#        evt.skip(false)
      else
        if evt.selection != Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW
          if can? :read, Helpers::ApplicationHelper::MODULI[evt.selection]
            self.set_page_image(evt.old_selection, (evt.old_selection * 2) + 1)
            main_frame.set_status_text('')
          else
            main_frame.set_status_text('Attenzione! Utente non autorizzato o modulo non abilitato.')
            evt.veto()
          end
        else
          self.set_page_image(evt.old_selection, (evt.old_selection * 2) + 1)
        end
      end
    end

    def listbook_page_changed(evt)
      begin
        case evt.selection
        when Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW
          anagrafica_notebook_mgr.current_page().init_folder()
        when Helpers::ApplicationHelper::WXBRA_FATTURAZIONE_VIEW
          fatturazione_notebook_mgr.current_page().init_folder()
          fatturazione_notebook_mgr.current_page().refresh()
        when Helpers::ApplicationHelper::WXBRA_SCADENZARIO_VIEW
          scadenzario_notebook_mgr.current_page().init_folder()
        when Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW
          prima_nota_notebook_mgr.current_page().init_folder()
        when Helpers::ApplicationHelper::WXBRA_MAGAZZINO_VIEW
          magazzino_notebook_mgr.current_page().init_folder()
        when Helpers::ApplicationHelper::WXBRA_CONFIGURAZIONE_VIEW
          configurazione_notebook_mgr.set_selection(Helpers::ConfigurazioneHelper::WXBRA_AZIENDA_FOLDER)
          configurazione_notebook_mgr.current_page().init_folder()
        end

        self.set_page_image(evt.selection, (evt.selection * 2))

      rescue Exception => e
        logger.error(e.message)
      end

      evt.skip()
    end

    def update_ui()
      notify(:evt_attivita_changed)
    end

  end
end
