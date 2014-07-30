# encoding: utf-8

require 'erb'
require 'app/helpers/printer_helper'
require 'app/helpers/wk_helper'
require 'app/controllers/base_controller'
require 'app/views/tool_bar'
require 'app/views/listbook_mgr'
require 'app/views/dialog/login_dialog'
require 'app/views/dialog/licenza_dialog'


module Views
  class MainFrame < Wx::Frame
    include Views::Base::View
    include Helpers::MVCHelper
    include Models
    include ERB::Util

    def initialize
      super()

      # screen resolution
      screen = Wx::Display.new
      configatron.screen.width = screen.geometry.width
      configatron.screen.height = screen.geometry.height

      res = Xrc.instance().resource
      res.load_frame_subclass(self, nil, "wxBra")
      set_icon(Wx::Icon.new('resources/images/paperclip.ico', Wx::BITMAP_TYPE_ICO))
      set_status_text(PaperclipConfig::Boot.info)
      ui()
      if PaperclipConfig::Boot.error
        log_error(self, PaperclipConfig::Boot.error)
        exit(1)
      end
    end

    def ui()
      controller :base

      splash_bitmap = Wx::Bitmap.new('resources/images/splash.png', Wx::BITMAP_TYPE_PNG)
      splash = Wx::SplashScreen.new(splash_bitmap,
                                    Wx::SPLASH_CENTRE_ON_SCREEN|Wx::SPLASH_NO_TIMEOUT,
                                    3000, self, -1)

      setup_listeners()

      setup_menu_bar()

      xrc = Xrc.instance()
      xrc.find('TOOL_BAR', self, :extends => Views::ToolBar)
      tool_bar.ui()

      xrc.find('LISTBOOK_MGR', self, :extends => Views::ListbookMgr)
      #listbook.remove_page(2)
      listbook_mgr.ui(self)
      listbook_mgr.set_selection(Helpers::ApplicationHelper::WXBRA_ANAGRAFICA_VIEW)

      evt_azienda_changed do | evt |
        if Utente.admin? || Utente.system?
          listbook_mgr.reset_folders()
        else
          login(false, evt.old)
        end
      end

      evt_force_exit do | evt |
        if evt.restart?
          $exit_code = Helpers::ApplicationHelper::RESTART_EXIT_CODE
        end
        Wx::get_app.exit_main_loop()
      end

      splash.destroy()

#      evt_menu(Wx::ID_EXIT) do
#        Wx::get_app.exit_main_loop()
#      end

#      evt_idle() do
#        logger.debug("********* EVENTO IDLE *********")
#      end

      map_events(self)

      evt_config_changed do | evt |
        write_config()
        set_status_text("Connesso al server #{evt.host}") if evt.host
      end

   end

    # menu
    def setup_menu_bar()
      @menu_bar = self.get_menu_bar()
      @mnu_esci = @menu_bar.find_menu_item('File', 'Esci')
      @mnu_cambia_utente = @menu_bar.find_menu_item('File', 'Cambia utente')
      mnu_fattura = @menu_bar.find_item(menu_bar.find_menu_item('Opzioni', 'Fattura')).get_sub_menu()
        @mnu_carta_intestata = mnu_fattura.find_item('Carta intestata')
        @menu_bar.find_item(@mnu_carta_intestata).check() if configatron.fatturazione.carta_intestata
        @mnu_iva_per_cassa = mnu_fattura.find_item('Iva per cassa')
        if configatron.fatturazione.has_key?(:iva_per_cassa)
          @menu_bar.find_item(@mnu_iva_per_cassa).check() if configatron.fatturazione.iva_per_cassa
        else
          configatron.fatturazione.iva_per_cassa = false
        end
        @mnu_commercio = mnu_fattura.find_item('Commercio')
        @mnu_servizi = mnu_fattura.find_item('Servizi')

      case configatron.attivita
      when Models::Azienda::ATTIVITA[:commercio]
        @menu_bar.find_item(@mnu_commercio).check()
      when Models::Azienda::ATTIVITA[:servizi]
        @menu_bar.find_item(@mnu_servizi).check()
      end

      mnu_prefattura = @menu_bar.find_item(menu_bar.find_menu_item('Opzioni', 'Proforma')).get_sub_menu()
        @mnu_nota_spese = mnu_prefattura.find_item('Nota spese')
        @mnu_avviso_fattura = mnu_prefattura.find_item('Avviso fattura')
        @mnu_avviso_parcella = mnu_prefattura.find_item('Avviso parcella')

      case configatron.pre_fattura.intestazione
      when 1
        @menu_bar.find_item(@mnu_nota_spese).check()
      when 2
        @menu_bar.find_item(@mnu_avviso_fattura).check()
      when 3
        @menu_bar.find_item(@mnu_avviso_parcella).check()
      end

      mnu_bilancio = @menu_bar.find_item(menu_bar.find_menu_item('Opzioni', 'Bilancio')).get_sub_menu()
        @mnu_bilancio_attivo = mnu_bilancio.find_item('Attivo')
        if configatron.bilancio.has_key?(:attivo)
          @menu_bar.find_item(@mnu_bilancio_attivo).check() if configatron.bilancio.attivo
        else
          configatron.bilancio.attivo = false
        end

      mnu_liquidazioni = @menu_bar.find_item(menu_bar.find_menu_item('Opzioni', 'Liquidazioni')).get_sub_menu()
        @mnu_liquidazioni_attivo = mnu_liquidazioni.find_item('Attivo')
        if configatron.liquidazioni.has_key?(:attivo)
          @menu_bar.find_item(@mnu_liquidazioni_attivo).check() if configatron.liquidazioni.attivo
        else
          configatron.liquidazioni.attivo = false
        end

      @mnu_licenza = menu_bar.find_menu_item('Registra', 'Licenza')

      @mnu_versione = menu_bar.find_menu_item('Info', 'Versione')

    end

    def login(exit_main=true, old_azienda=nil)
      login_dlg = Views::Dialog::LoginDialog.new(self)
      login_dlg.center_on_screen(Wx::BOTH)
      answer = login_dlg.show_modal()
      login_dlg.destroy()
      if answer == Wx::ID_CANCEL
        logger.debug("exit_main: #{exit_main}")
        if exit_main
          Wx::get_app.exit_main_loop()
        else
          if old_azienda
            Models::Azienda.current = ctrl.load_azienda(old_azienda)
            tool_bar.chce_azienda.view_data = old_azienda
          end
        end
      else
        #tool_bar.init_panel()
        if ctrl.licenza.scaduta?
          Wx::message_box("Periodo di attivazione scaduto il #{ctrl.licenza.get_data_scadenza.to_s(:italian_date)}. Rinnovare la licenza.",
            'Licenza',
            Wx::OK | Wx::ICON_WARNING, self)
          #listbook_mgr.enable(false)
        else
          data_scadenza = ctrl.licenza.get_data_scadenza()
          if((giorni_alla_scadenza = (data_scadenza - Date.today).to_i) < 7)
            Wx::message_box("Mancano #{giorni_alla_scadenza} giorni alla scadenza del periodo di attivazione.",
              'Licenza',
              Wx::OK | Wx::ICON_WARNING, self)
          end
      
        end

        Wx::BusyCursor.busy() do
          listbook_mgr.reset_folders()
#            listbook_mgr.init_folders()
        end
      
        tool_bar.chce_azienda.view_data = Models::Azienda.current.id
      
        if Models::Azienda.current.dati_azienda.denominazione =~ /DEMO/
          listbook_mgr.set_selection(Helpers::ApplicationHelper::WXBRA_CONFIGURAZIONE_VIEW)
          listbook_mgr.configurazione_notebook_mgr.set_selection(Helpers::ConfigurazioneHelper::WXBRA_AZIENDA_FOLDER)
          Wx::message_box("Compila i dati dell'azienda per una corretta gestione delle stampe.",
            'Licenza',
            Wx::OK | Wx::ICON_INFORMATION, self)
        end
        
    
        logger.info("nessun errore...")

      end

    end

    def mnu_esci_click(evt)
      Wx::get_app.exit_main_loop()
    end

    def mnu_cambia_utente_click(evt)
      login(false)
    end

    def mnu_nota_spese_click(evt)
      begin
        Wx::BusyCursor.busy() do
          if evt.checked?
            configatron.pre_fattura.intestazione = 1
            notify(:evt_prefattura_changed)
            @menu_bar.find_item(@mnu_avviso_fattura).check(false)
            @menu_bar.find_item(@mnu_avviso_parcella).check(false)
            write_config()
          end
        end

      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_avviso_fattura_click(evt)
      begin
        Wx::BusyCursor.busy() do
          if evt.checked?
            configatron.pre_fattura.intestazione = 2
            notify(:evt_prefattura_changed)
            @menu_bar.find_item(@mnu_nota_spese).check(false)
            @menu_bar.find_item(@mnu_avviso_parcella).check(false)
            write_config()
          end
        end

      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_avviso_parcella_click(evt)
      begin
        Wx::BusyCursor.busy() do
          if evt.checked?
            configatron.pre_fattura.intestazione = 3
            notify(:evt_prefattura_changed)
            @menu_bar.find_item(@mnu_nota_spese).check(false)
            @menu_bar.find_item(@mnu_avviso_fattura).check(false)
            write_config()
          end
        end

      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_carta_intestata_click(evt)
      begin
        Wx::BusyCursor.busy() do
          configatron.fatturazione.carta_intestata = evt.checked?
          write_config()
        end
      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_iva_per_cassa_click(evt)
      begin
        Wx::BusyCursor.busy() do
          configatron.fatturazione.iva_per_cassa = evt.checked?
          write_config()
        end
      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_commercio_click(evt)
      begin
        Wx::BusyCursor.busy() do
          if evt.checked?
            res = Wx::message_box("Paperclip sarà riavviato. Confermi le nuove impostazioni?",
              'Avvertenza',
                  Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

            if res == Wx::YES
              configatron.attivita = Models::Azienda::ATTIVITA[:commercio]
              write_config()
              Models::Azienda.current.update_attribute(:attivita_merc, Models::Azienda::ATTIVITA[:commercio])
#              if PaperclipConfig::Boot.windows_platform?
#                Process.create(:app_name => 'paperclip.exe')
#              else
#                # TODO
#                # linea di comando per avviare l'applicazione su macosx/linux
#                exec("paperclip.exe")
#              end
              # Wx::get_app.exit_main_loop()
              evt_f_exit = Views::Base::CustomEvent::ForceExitEvent.new(true)
              process_event(evt_f_exit)
            else
              @menu_bar.find_item(@mnu_commercio).check(false)
              @menu_bar.find_item(@mnu_servizi).check()
            end
          end
        end

      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_servizi_click(evt)
      begin
        Wx::BusyCursor.busy() do
          if evt.checked?
            res = Wx::message_box("Paperclip sarà riavviato. Confermi le nuove impostazioni?",
              'Avvertenza',
              Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

            if res == Wx::YES
              configatron.attivita = Models::Azienda::ATTIVITA[:servizi]
              write_config()
              Models::Azienda.current.update_attribute(:attivita_merc, Models::Azienda::ATTIVITA[:servizi])
#              if PaperclipConfig::Boot.windows_platform?
#                Process.create(:app_name => 'paperclip.exe')
#              else
#                # TODO
#                # linea di comando per avviare l'applicazione su macosx/linux
#                exec("paperclip.exe")
#              end
              # Wx::get_app.exit_main_loop()
              evt_f_exit = Views::Base::CustomEvent::ForceExitEvent.new(true)
              process_event(evt_f_exit)
            else
              @menu_bar.find_item(@mnu_commercio).check()
              @menu_bar.find_item(@mnu_servizi).check(false)
            end
          end
        end

      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_bilancio_attivo_click(evt)
      begin
        Wx::BusyCursor.busy() do
          res = Wx::message_box("Paperclip sarà riavviato. Confermi le nuove impostazioni?",
            'Avvertenza',
            Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

          if res == Wx::YES
            configatron.bilancio.attivo = evt.checked?
            write_config()
            evt_f_exit = Views::Base::CustomEvent::ForceExitEvent.new(true)
            process_event(evt_f_exit)
          else
            @menu_bar.find_item(@mnu_bilancio_attivo).check(!evt.checked?)
          end
          # configatron.bilancio.attivo = evt.checked?
          # write_config()
          # listbook_mgr.reset_folders()
          # notify(:evt_bilancio_attivo, evt.checked?)
          # logger.debug("configatron.bilancio.attivo: #{configatron.bilancio.attivo}")
        end
      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_liquidazioni_attivo_click(evt)
      begin
        Wx::BusyCursor.busy() do
          configatron.liquidazioni.attivo = evt.checked?
          write_config()
          listbook_mgr.reset_folders()
          notify(:evt_liquidazioni_attivo, evt.checked?)
          logger.debug("configatron.liquidazioni.attivo: #{configatron.liquidazioni.attivo}")
        end
      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_licenza_click(evt)
      begin
        licenza_dlg = Views::Dialog::LicenzaDialog.new(self)

        res = licenza_dlg.show_modal()

        if res == Wx::ID_OK
          listbook_mgr.enable()
        end

        licenza_dlg.destroy()

      rescue Exception => e
        log_error(self, e)
      end
    end

    def mnu_versione_click(evt)
      begin
        Wx::about_box( :name => 'Paperclip',
               :version => Versione::RELEASE,
               :developers => ['Fabio Petrucci'])
#        Wx::message_box("PaperClip v. #{ctrl.licenza.versione}",
#          'Versione',
#          Wx::OK | Wx::ICON_INFORMATION, self)

      rescue Exception => e
        log_error(self, e)
      end
    end

    private

    def write_config()
      # begin to remove
      begin
        File.open(Helpers::ApplicationHelper::WXBRA_CONF_PATH, "w") { |f|
          f.write(configatron.to_hash.to_yaml)
        }
      rescue
        raise RuntimeError, "Can't write file: #{Helpers::ApplicationHelper::WXBRA_CONF_PATH}"
      end
      # end to remove

#      begin
#        File.open(Helpers::ApplicationHelper::PAPERCLIP_CONF_PATH, "w") { |f|
#          f.write("configatron.configure_from_hash(#{configatron.to_hash})")
#        }
#      rescue
#        raise RuntimeError, "Can't write file: #{Helpers::ApplicationHelper::PAPERCLIP_CONF_PATH}"
#      end

    end

  end
end
