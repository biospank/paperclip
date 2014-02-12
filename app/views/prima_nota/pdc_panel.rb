# encoding: utf-8

require 'app/views/base/base_panel'
require 'app/views/dialog/pdc_dialog'
require 'app/views/dialog/categorie_pdc_dialog'

module Views
  module PrimaNota
    module PdcPanel
      include Views::Base::Panel
      include Helpers::MVCHelper
      
      attr_accessor :dialog_sql_criteria # utilizzato nelle dialog
      
      def ui()

        model :pdc => {:attrs => [:categoria_pdc,
                                   :codice,
                                   :descrizione,
                                   :banca,
                                   :attivo]}
        
        controller :prima_nota

        logger.debug('initializing PdcPanel...')
        xrc = Xrc.instance()
        # NotaSpese
        
        xrc.find('lku_categoria_pdc', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|categoria| self.txt_descrizione_categoria_pdc.view_data = (categoria ? categoria.descrizione : nil)},
                                :model => :categoria_pdc,
                                :dialog => :categorie_pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
        end

        xrc.find('txt_descrizione_categoria_pdc', self, :extends => TextField)

        xrc.find('txt_codice', self, :extends => LookupTextField) do |field|
          field.evt_char { |evt| txt_codice_keypress(evt) }
        end
        xrc.find('txt_descrizione', self, :extends => TextField)

        xrc.find('lku_banca', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|banca| self.txt_descrizione_banca.view_data = (banca ? banca.descrizione : nil)},
                                :model => :banca,
                                :dialog => :banche_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_PDC_FOLDER)
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)

        xrc.find('chk_attivo', self, :extends => CheckField)

        xrc.find('btn_variazione', self)
        xrc.find('btn_salva', self)
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuovo', self)

        disable_widgets [btn_elimina]
        
        map_events(self)

        subscribe(:evt_azienda_changed) do
          reset_panel()
        end

        subscribe(:evt_categoria_pdc_changed) do |data|
          lku_categoria_pdc.load_data(data)
        end

        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        subscribe(:evt_new_pdc) do
          reset_panel()
        end

        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F3, btn_variazione.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuovo.get_id ]
        ]                            
        self.accelerator_table = acc_table  
      end

      def init_panel()
        reset_pdc_command_state()

        lku_categoria_pdc.activate()
        
      end
      
      def reset_panel()
        begin
          reset_pdc()
          
          reset_pdc_command_state()

          lku_categoria_pdc.activate()
          
        rescue Exception => e
          log_error(self, e)
        end
        
      end

      # Gestione eventi

      def txt_codice_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if pdc = ctrl.load_pdc_by_codice(txt_codice.view_data)
              self.pdc = pdc
              transfer_pdc_to_view()
              reset_pdc_command_state()
            end
            evt.skip()
          when Wx::K_F5
            self.dialog_sql_criteria = self.categoria_sql_criteria()
            btn_variazione_click(evt)
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def btn_variazione_click(evt)
        begin
          transfer_pdc_from_view()
          pdc_dlg = Views::Dialog::PdcDialog.new(self, false)
          pdc_dlg.center_on_screen(Wx::BOTH)
          if pdc_dlg.show_modal() == Wx::ID_OK
            self.pdc = ctrl.load_pdc(pdc_dlg.selected)
            transfer_pdc_to_view()
            reset_pdc_command_state()
            lku_categoria_pdc.activate() if lku_categoria_pdc.enabled?
            
          else
            logger.debug("You pressed Cancel")
          end

          pdc_dlg.destroy()

        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def btn_salva_click(evt)
        begin
          if btn_salva.enabled?
            Wx::BusyCursor.busy() do
              if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
                transfer_pdc_from_view()
                if self.pdc.valid?
                  ctrl.save_pdc()
                  evt_chg = Views::Base::CustomEvent::PdcChangedEvent.new(ctrl.search_pdc())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  Wx::message_box('Salvataggio avvenuto correttamente.',
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)
                  reset_panel()
                  process_event(Views::Base::CustomEvent::BackEvent.new())
                else
                  Wx::message_box(self.pdc.error_msg,
                    'Info',
                    Wx::OK | Wx::ICON_INFORMATION, self)

                  focus_pdc_error_field()

                end
              else
                Wx::message_box('Utente non autorizzato.',
                  'Info',
                  Wx::OK | Wx::ICON_INFORMATION, self)
              end
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
      
      def btn_elimina_click(evt)
        begin
          if btn_elimina.enabled?
            if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
              res = Wx::message_box("Confermi l'eliminazione?",
                'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

              if res == Wx::YES
                Wx::BusyCursor.busy() do
                  ctrl.delete_pdc()
                  evt_chg = Views::Base::CustomEvent::PdcChangedEvent.new(ctrl.search_pdc())
                  # This sends the event for processing by listeners
                  process_event(evt_chg)
                  reset_panel()
                end
              end

            else
              Wx::message_box('Utente non autorizzato.',
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)
            end
            lku_categoria_pdc.activate()
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
      
      def btn_nuovo_click(evt)
        begin
          self.reset_panel()
        rescue Exception => e
          log_error(self, e)
        end

        evt.skip()
      end
      
      def reset_pdc_command_state()
        if pdc.new_record?
          disable_widgets [btn_elimina]
          enable_widgets [lku_categoria_pdc, txt_codice, txt_descrizione, lku_banca]
        else
          if pdc.modificabile?
            enable_widgets [btn_elimina, lku_categoria_pdc, txt_codice, txt_descrizione, lku_banca]
          else
            disable_widgets [btn_elimina, lku_categoria_pdc, txt_codice, txt_descrizione]

            if lku_banca.view_data
              lku_banca.enable(false)
            else
              if pdc.attivo? || pdc.passivo?
                lku_banca.enable(true)
              else
                lku_banca.enable(false)
              end
            end


          end
        end
      end

      def categoria_sql_criteria()
        if categoria = lku_categoria_pdc.view_data()
          "pdc.categoria_pdc_id = #{categoria.id}"
        end
      end
    end
  end
end