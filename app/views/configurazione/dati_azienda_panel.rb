# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module Configurazione
    module DatiAziendaPanel
      include Views::Base::Panel
      include Helpers::MVCHelper

      def ui

        model :dati_azienda => {:attrs => []}
        controller :configurazione

        logger.debug('initializing DatiAziendaPanel...')
        xrc = Xrc.instance()
        # dati_azienda
        xrc.find('txt_denominazione', self, :extends => TextField)
        xrc.find('txt_p_iva', self, :extends => TextField)
        xrc.find('txt_cod_fisc', self, :extends => TextField)
        xrc.find('txt_indirizzo', self, :extends => TextField)
        xrc.find('txt_cap', self, :extends => TextField)
        xrc.find('txt_citta', self, :extends => TextField)
        xrc.find('txt_comune', self, :extends => TextField)
        xrc.find('txt_provincia', self, :extends => TextField)
        xrc.find('chce_regime_fiscale', self, :extends => ChoiceField)do |chce|
          chce.load_data(Helpers::ApplicationHelper::Fatturazione::REGIMI_FISCALI)
        end
        xrc.find('chce_liquidazione_iva', self, :extends => ChoiceField) do |chce|
          chce.load_data(Helpers::ApplicationHelper::Liquidazione::PERIODO,
            :label => :descrizione,
            :select => :first)
        end
        xrc.find('txt_cap_soc', self, :extends => DecimalField)
        xrc.find('txt_reg_imprese', self, :extends => TextField)
        xrc.find('txt_num_reg_imprese', self, :extends => TextNumericField)
        xrc.find('txt_num_rea', self, :extends => TextField)
        xrc.find('txt_iban', self, :extends => TextField)
        xrc.find('txt_telefono', self, :extends => TextField)
        xrc.find('txt_fax', self, :extends => TextField)
        xrc.find('txt_e_mail', self, :extends => TextField)
        xrc.find('img_logo', self, :extends => ImageLogoField)

        xrc.find('btn_logo', self)
        xrc.find('btn_rimuovi', self)
        xrc.find('btn_salva', self)

        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([chce_liquidazione_iva]) : disable_widgets([chce_liquidazione_iva])
        end

        subscribe(:evt_liquidazioni_attivo) do |data|
          data ? enable_widgets([chce_liquidazione_iva]) : disable_widgets([chce_liquidazione_iva])
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      def init_panel()
        self.dati_azienda = load_dati_azienda()
        transfer_dati_azienda_to_view()
        img_logo.refresh
      end

      def reset_panel()
        reset_dati_azienda()
        init_panel()
      end
      # Gestione eventi

      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            if ctrl.licenza.attiva?
              if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
                transfer_dati_azienda_from_view()
                if self.dati_azienda.valid?
                  Wx::BusyCursor.busy() do
                    ctrl.save_dati_azienda()
                    evt_upd = Views::Base::CustomEvent::AziendaUpdatedEvent.new()
                    # This sends the event for processing by listeners
                    process_event(evt_upd)
                  end
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                else
                  Wx::message_box(self.dati_azienda.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_dati_azienda_error_field()

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

      def btn_logo_click(evt)
        begin
          if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
            Wx::message_box("Per una corretta visualizzazione, il logo deve essere del seguente formato: 302x113px - 8,00x3,00cm",
              'Formato logo',
              Wx::OK | Wx::ICON_INFORMATION, self)
            # nuove stampe
#            Wx::message_box("Per una corretta visualizzazione, l'altezza del logo deve essere al massimo di 90px",
#              'Formato logo',
#              Wx::OK | Wx::ICON_INFORMATION, self)
            wildcard = "Immagine jpg (*.jpg)|*.jpg|Immagine png (*.png)|*.png|Immagine bmp (*.bmp)|*.bmp|Immagine gif (*.gif)|*.gif"
            dlg = Wx::FileDialog.new(self, "Scegli il logo", Dir.getwd(), "", wildcard, Wx::OPEN | Wx::FD_FILE_MUST_EXIST)
            if dlg.show_modal() == Wx::ID_OK
              img = Wx::Image.new(dlg.path(), Wx::BITMAP_TYPE_ANY)
              if img.height > Helpers::ConfigurazioneHelper::WXBRA_LOGO_HEIGHT ||
                  img.width > Helpers::ConfigurazioneHelper::WXBRA_LOGO_WIDTH
                Wx::message_box("Il formato dell'immagine selezionata eccede la dimensione massima (302x113px - 8,00x3,00cm)",
                  'Formato logo',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              else
                self.dati_azienda.logo_tipo = dlg.path().split('.').last()
                img_logo.view_data = open(dlg.path(), "rb") {|io| io.read }
                img_logo.refresh
              end
            end
          else
            Wx::message_box('Utente non autorizzato.',
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
          end
        rescue Exception => e
          log_error(self, e)
        end
        evt.skip()
      end

      def btn_rimuovi_click(evt)
        begin
          if can? :write, Helpers::ApplicationHelper::Modulo::CONFIGURAZIONE
            img_logo.view_data = nil
            img_logo.set_bitmap(Wx::Bitmap.new(File.join(Helpers::ApplicationHelper::WXBRA_IMAGES_PATH, 'blank_logo.png'), Wx::BITMAP_TYPE_ANY))
          else
            Wx::message_box('Utente non autorizzato.',
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)
          end
        rescue Exception => e
          log_error(self, e)
        end
        evt.skip()
      end

    end
  end
end
