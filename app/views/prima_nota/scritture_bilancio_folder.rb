# encoding: utf-8

require 'app/controllers/prima_nota_controller'
require 'app/helpers/prima_nota_helper'
require 'app/views/dialog/causali_dialog'
require 'app/views/dialog/banche_dialog'
require 'app/views/dialog/pdc_dialog'
require 'app/views/prima_nota/scritture_common_actions'

module Views
  module PrimaNota
    module ScrittureBilancioFolder
      include Views::PrimaNota::ScrittureCommonActions

      def ui()

        model :scrittura => {:attrs => [:data_operazione,
                                          :causale,
                                          :descrizione,
                                          :importo,
                                          :pdc_dare,
                                          :pdc_avere]},
              :filtro => {:attrs => [:anno, :dal, :al]}

        controller :prima_nota

        logger.debug('initializing ScrittureFolder...')
        xrc = Xrc.instance()
        # Fattura cliente

        xrc.find('txt_data_operazione', self, :extends => DateField)
        xrc.find('lku_causale', self, :extends => LookupLooseField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|causale| self.txt_descrizione_causale.view_data = (causale ? causale.descrizione : nil)},
                                :model => :causale,
                                :dialog => :causali_dialog,
                                :default => lambda {|causale| causale.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
        end

        subscribe(:evt_causale_changed) do |data|
          lku_causale.load_data(data)
        end

        xrc.find('txt_descrizione_causale', self, :extends => TextField)

        xrc.find('txt_descrizione', self, :extends => TextField) do |field|
          field.evt_char { |evt| txt_descrizione_keypress(evt) }
        end

        xrc.find('txt_importo', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_importo_keypress(evt) }
        end

        xrc.find('lku_pdc_dare', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_dare.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_dare', self, :extends => TextField)

        xrc.find('lku_pdc_avere', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|pdc| self.txt_descrizione_pdc_avere.view_data = (pdc ? pdc.descrizione : nil)},
                                :model => :pdc,
                                :dialog => :pdc_dialog,
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
        end

        xrc.find('txt_descrizione_pdc_avere', self, :extends => TextField)

        # il pdc delle scritture deve caricare anche i conti dei clienti e dei fornitori
        lku_pdc_dare.load_data(Models::Pdc.search(:all,
            :conditions => dare_sql_criteria,
            :joins => :categoria_pdc
          )
        )

        lku_pdc_avere.load_data(Models::Pdc.search(:all,
            :conditions => avere_sql_criteria,
            :joins => :categoria_pdc
          )
        )

        subscribe(:evt_pdc_changed) do |data|
          lku_pdc_dare.load_data(Models::Pdc.search(:all,
            :conditions => dare_sql_criteria,
            :joins => :categoria_pdc
          ))
          lku_pdc_avere.load_data(Models::Pdc.search(:all,
            :conditions => avere_sql_criteria,
            :joins => :categoria_pdc
          ))
        end

        subscribe(:evt_bilancio_attivo) do |data|
          data ? enable_widgets([lku_pdc_dare, lku_pdc_avere]) : disable_widgets([lku_pdc_dare, lku_pdc_avere])
        end

        xrc.find('chce_anno', self, :extends => ChoiceStringField)

        subscribe(:evt_anni_contabili_scrittura_changed) do |data|
          chce_anno.load_data(data, :select => :last)
        end

        xrc.find('txt_dal', self, :extends => DateField)
        xrc.find('txt_al', self, :extends => DateField)
        xrc.find('lstrep_scritture', self, :extends => EditableReportField) do |list|
          list.column_info([{:caption => 'Data', :width => 80, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Tipo', :width => 40, :align => Wx::LIST_FORMAT_CENTRE},
            {:caption => 'Descrizione', :width => 220, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Importo', :width => 120, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Conto Dare', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Conto Avere', :width => 200, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Causale', :width => 150, :align => Wx::LIST_FORMAT_LEFT}
          ])

          tipologia = Proc.new do |scrittura|
            tipo = ''
            if scrittura.esterna?
              tipo = 'A'
              if scrittura.stornata?
                tipo = 'AS'
              end
            else
              tipo = 'M'
              if scrittura.stornata?
                tipo = 'MS'
              end
            end
            tipo
          end

          list.data_info([{:attr => :data_operazione, :format => :date},
            {:attr => tipologia},
            {:attr => :descrizione},
            {:attr => :importo, :format => :currency},
            {:attr => lambda {|scrittura| (scrittura.pdc_dare ? "#{scrittura.pdc_dare.codice} - #{scrittura.pdc_dare.descrizione}" : '')}},
            {:attr => lambda {|scrittura| (scrittura.pdc_avere ? "#{scrittura.pdc_avere.codice} - #{scrittura.pdc_avere.descrizione}" : '')}},
            {:attr => lambda {|scrittura| (scrittura.causale ? scrittura.causale.descrizione : '')}}
          ])
        end

        xrc.find('btn_salva', self) do |button|
          button.move_after_in_tab_order(lku_pdc_avere)
        end
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuova', self)
        xrc.find('btn_ricerca', self)

        map_events(self)

        map_text_enter(self, {'lku_causale' => 'on_riga_text_enter',
                              'txt_importo' => 'on_riga_text_enter',
                              'lku_pdc_dare' => 'on_riga_text_enter',
                              'lku_pdc_avere' => 'on_riga_text_enter',
                              'txt_data_operazione' => 'on_riga_text_enter',
                              'txt_dal' => 'on_ricerca_text_enter',
                              'txt_al' => 'on_ricerca_text_enter'})


        subscribe(:evt_azienda_changed) do
          reset_folder()
          display_scritture()
        end

        subscribe(:evt_dettaglio_scrittura) do |s|
          reset_gestione_riga()
          self.scrittura = s
          transfer_scrittura_to_view()
          update_riga_ui()
          txt_data_operazione.activate()
        end

        evt_menu(WX_ID_F2) do
          lstrep_scritture.activate()
        end

        subscribe(:evt_prima_nota_changed) do |scritture|
          reset_folder()
          display_scritture(scritture)
        end
        # accelerator table
        acc_table = Wx::AcceleratorTable[
          [ Wx::ACCEL_NORMAL, Wx::K_F2, WX_ID_F2 ],
          [ Wx::ACCEL_NORMAL, Wx::K_F8, btn_salva.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F10, btn_elimina.get_id ],
          [ Wx::ACCEL_NORMAL, Wx::K_F12, btn_nuova.get_id ]
        ]
        self.accelerator_table = acc_table
      end

      # Gestione eventi

      def txt_descrizione_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              lku_causale.activate()
            else
              activate_field(txt_importo, lku_pdc_dare, lku_pdc_avere,
               btn_salva)
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_importo_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              txt_descrizione.activate()
            else
              activate_field(lku_pdc_dare, lku_pdc_avere,
               btn_salva)
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_pdc_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              activate_field(txt_importo, txt_descrizione)
            else
              activate_field(lku_pdc_avere,
               btn_salva)
            end
          when Wx::K_F5
            self.dialog_sql_criteria = self.dare_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc_dare.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_dare_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                  Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER
                ]
              )
              process_event(evt_new)
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_pdc_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              activate_field(lku_pdc_dare, txt_importo, txt_descrizione)
            else
              activate_field(btn_salva)
            end
          when Wx::K_F5
            self.dialog_sql_criteria = self.avere_sql_criteria()
            dlg = Views::Dialog::PdcDialog.new(self)
            dlg.center_on_screen(Wx::BOTH)
            answer = dlg.show_modal()
            if answer == Wx::ID_OK
              lku_pdc_avere.view_data = ctrl.load_pdc(dlg.selected)
              lku_pdc_avere_after_change()
            elsif(answer == dlg.btn_nuovo.get_id)
              evt_new = Views::Base::CustomEvent::NewEvent.new(
                :pdc,
                [
                  Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                  Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER
                ]
              )
              process_event(evt_new)
            end

            dlg.destroy()

          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def on_riga_text_enter(evt)
        begin
          lku_causale.match_selection()
          lku_pdc_dare.match_selection()
          lku_pdc_avere.match_selection()
          btn_salva_click(evt)
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_causale_after_change()
        begin
          causale = lku_causale.match_selection()
          txt_descrizione.view_data = causale.descrizione_agg if causale
          lku_pdc_dare.view_data = causale.pdc_dare
          lku_pdc_avere.view_data = causale.pdc_avere
          transfer_scrittura_from_view()
          update_riga_ui()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_causale_loose_focus()
        begin
          if causale = lku_causale.match_selection()
            txt_descrizione.view_data = causale.descrizione_agg
            lku_pdc_dare.view_data = causale.pdc_dare
            lku_pdc_avere.view_data = causale.pdc_avere
          end
          transfer_scrittura_from_view()
          update_riga_ui()
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
                if can? :write, Helpers::ApplicationHelper::Modulo::PRIMA_NOTA
                  if scrittura.esterna? or scrittura.congelata?
                    Wx::message_box("Questa scrittura non puo' essere modificata.",
                      'Info',
                      Wx::OK | Wx::ICON_INFORMATION, self)
                  else
                    transfer_scrittura_from_view()
                    if self.scrittura.post_datata?
                      res = Wx::message_box("Si sta inserendo un movimento con data successiva alla data odierna.\nContinuare?",
                        'Domanda',
                        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                      if res == Wx::NO
                        txt_data_operazione.activate()
                        return
                      end
                    end

                    if self.scrittura.valid?
                      if self.scrittura.con_importo_valido?
                        if scrittura_compatibile?
                          if self.scrittura.new_record?
                            ctrl.save_scrittura()
                            reset_filtro()
                            notify(:evt_prima_nota_changed, ctrl.search_scritture())
                          else
                            ctrl.save_scrittura()
                            if filtro.dal || filtro.al
                              notify(:evt_prima_nota_changed, ctrl.ricerca_scritture())
                            else
                              notify(:evt_prima_nota_changed, ctrl.search_scritture())
                            end
                          end
                        end
                      else
                        Wx::message_box("Inserire l'importo.",
                          'Info',
                          Wx::OK | Wx::ICON_INFORMATION, self)
                        activate_field(txt_importo)

                      end
                    else
                      Wx::message_box(self.scrittura.error_msg,
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)

                      focus_scrittura_error_field()

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
        rescue Exception => e
          log_error(self, e)
        end

      end

      def reset_gestione_riga()
        reset_scrittura()
        lku_causale.set_default()
        txt_data_operazione.view_data = Date.today if txt_data_operazione.view_data.blank?
      end

      def scrittura_compatibile?

        if self.scrittura.pdc_dare && self.scrittura.pdc_dare.ricavo?
          res = Wx::message_box("Il conto in dare non è un costo.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_pdc_dare.activate()
              return false
            end
        end

        if self.scrittura.pdc_avere && self.scrittura.pdc_avere.costo?
          res = Wx::message_box("Il conto in avere non è un ricavo.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_pdc_avere.activate()
              return false
            end
        end

        if(((self.scrittura.pdc_dare && self.scrittura.pdc_dare.costo?) &&
              (self.scrittura.pdc_avere && self.scrittura.pdc_avere.ricavo?)) ||
            ((self.scrittura.pdc_dare && self.scrittura.pdc_dare.ricavo?) &&
              (self.scrittura.pdc_avere && self.scrittura.pdc_avere.costo?)))

          res = Wx::message_box("Presenza di due conti economici.\nVuoi forzare il dato?",
            'Avvertenza',
            Wx::YES_NO | Wx::NO_DEFAULT | Wx::ICON_QUESTION, self)

            if res == Wx::NO
              lku_pdc_dare.activate()
              return false
            end
        end

        return true
      end

      def update_riga_ui()
        if self.scrittura.new_record?
          enable_widgets [txt_data_operazione, lku_causale,
                          txt_descrizione, txt_importo, lku_pdc_dare, lku_pdc_avere,
                          btn_salva, btn_nuova]
          disable_widgets [btn_elimina]
          toggle_fields()
        else
          if self.scrittura.esterna?
            disable_widgets [txt_data_operazione, lku_causale,
                            txt_descrizione, txt_importo, lku_pdc_dare, lku_pdc_avere,
                            btn_salva, btn_elimina]
            enable_widgets [btn_nuova]
          else
            if self.scrittura.congelata?
              disable_widgets [txt_data_operazione, lku_causale,
                              txt_descrizione, txt_importo, lku_pdc_dare, lku_pdc_avere,
                              btn_salva]
              enable_widgets [btn_elimina, btn_nuova]
            else
              enable_widgets [txt_data_operazione, lku_causale,
                              txt_descrizione, txt_importo, lku_pdc_dare, lku_pdc_avere,
                              btn_salva, btn_elimina, btn_nuova]
              toggle_fields()
            end
          end
        end
      end

      def toggle_fields()
        if causale = self.scrittura.causale
          causale.pdc_dare ? enable_widgets([lku_pdc_dare]) : (disable_widgets([lku_pdc_dare]); lku_pdc_dare.view_data = nil)
          causale.pdc_avere ? enable_widgets([lku_pdc_avere]) : (disable_widgets([lku_pdc_avere]); lku_pdc_avere.view_data = nil)
        else
          enable_widgets [txt_importo, lku_pdc_dare, lku_pdc_avere]

        end
      end

      def dare_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::COSTO}')"
      end

      def avere_sql_criteria()
        "categorie_pdc.type in ('#{Models::CategoriaPdc::ATTIVO}', '#{Models::CategoriaPdc::PASSIVO}', '#{Models::CategoriaPdc::RICAVO}')"
      end

      def include_hidden_pdc()
        true
      end

    end
  end
end
