# encoding: utf-8

require 'app/controllers/prima_nota_controller'
require 'app/helpers/prima_nota_helper'
require 'app/views/dialog/causali_dialog'
require 'app/views/dialog/banche_dialog'
require 'app/views/prima_nota/scritture_common_actions'

module Views
  module PrimaNota
    module ScrittureFolder
      include Views::PrimaNota::ScrittureCommonActions

      def ui()

        model :scrittura => {:attrs => [:data_operazione,
                                          :causale,
                                          :banca,
                                          :descrizione,
                                          :cassa_dare,
                                          :cassa_avere,
                                          :banca_dare,
                                          :banca_avere,
                                          :fuori_partita_dare,
                                          :fuori_partita_avere]},
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

        xrc.find('lku_banca', self, :extends => LookupField) do |field|
          field.configure(:code => :codice,
                                :label => lambda {|banca| self.txt_descrizione_banca.view_data = (banca ? banca.descrizione : nil)},
                                :model => :banca,
                                :dialog => :banche_dialog,
                                :default => lambda {|banca| banca.predefinita?},
                                :view => Helpers::ApplicationHelper::WXBRA_PRIMA_NOTA_VIEW,
                                :folder => Helpers::PrimaNotaHelper::WXBRA_SCRITTURE_FOLDER)
        end

        subscribe(:evt_banca_changed) do |data|
          lku_banca.load_data(data)
        end

        xrc.find('txt_descrizione_banca', self, :extends => TextField)

        xrc.find('txt_descrizione', self, :extends => TextField) do |field|
          field.evt_char { |evt| txt_descrizione_keypress(evt) }
        end
        xrc.find('txt_cassa_dare', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_cassa_dare_keypress(evt) }
        end
        xrc.find('txt_cassa_avere', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_cassa_avere_keypress(evt) }
        end
        xrc.find('txt_banca_dare', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_banca_dare_keypress(evt) }
        end
        xrc.find('txt_banca_avere', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_banca_avere_keypress(evt) }
        end
        xrc.find('txt_fuori_partita_dare', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_fuori_partita_dare_keypress(evt) }
        end
        xrc.find('txt_fuori_partita_avere', self, :extends => DecimalField) do |field|
          field.evt_char { |evt| txt_fuori_partita_avere_keypress(evt) }
        end
        xrc.find('lbl_saldo_cassa', self)
        xrc.find('lbl_saldo_banca', self)

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
            {:caption => 'Cassa (D)', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Cassa (A)', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Banca (D)', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Banca (A)', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'F. P. (D)', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'F. P. (A)', :width => 80, :align => Wx::LIST_FORMAT_RIGHT},
            {:caption => 'Causale', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
            {:caption => 'Banca', :width => 150, :align => Wx::LIST_FORMAT_LEFT},
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
            {:attr => :cassa_dare,  :format => :currency},
            {:attr => :cassa_avere,  :format => :currency},
            {:attr => :banca_dare,  :format => :currency},
            {:attr => :banca_avere,  :format => :currency},
            {:attr => :fuori_partita_dare,  :format => :currency},
            {:attr => :fuori_partita_avere,  :format => :currency},
            {:attr => lambda {|scrittura| (scrittura.causale ? scrittura.causale.descrizione : '')}},
            {:attr => lambda {|scrittura| (scrittura.banca ? scrittura.banca.descrizione : '')}},
          ])
        end

        xrc.find('btn_salva', self) do |button|
          button.move_after_in_tab_order(txt_fuori_partita_avere)
        end
        xrc.find('btn_elimina', self)
        xrc.find('btn_nuova', self)
        xrc.find('btn_ricerca', self)

        map_events(self)

        map_text_enter(self, {'lku_causale' => 'on_riga_text_enter',
                              'lku_banca' => 'on_riga_text_enter',
                              'txt_data_operazione' => 'on_riga_text_enter',
                              'txt_cassa_dare' => 'on_riga_text_enter',
                              'txt_cassa_avere' => 'on_riga_text_enter',
                              'txt_banca_dare' => 'on_riga_text_enter',
                              'txt_banca_avere' => 'on_riga_text_enter',
                              'txt_fuori_partita_dare' => 'on_riga_text_enter',
                              'txt_fuori_partita_avere' => 'on_riga_text_enter',
                              'txt_dal' => 'on_ricerca_text_enter',
                              'txt_al' => 'on_ricerca_text_enter'})


        subscribe(:evt_azienda_changed) do
          reset_folder()
          riepilogo_saldi()
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
          riepilogo_saldi()
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
              lku_banca.activate()
            else
              activate_field(txt_cassa_dare, txt_cassa_avere,
               txt_banca_dare, txt_banca_avere,
               txt_fuori_partita_dare, txt_fuori_partita_avere,
               btn_salva)
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_cassa_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              txt_descrizione.activate()
            else
              if scrittura.causale
                copy_field(txt_cassa_dare.view_data)
                activate_field(txt_cassa_avere,
                 txt_banca_dare, txt_banca_avere,
                 txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              else
                activate_field(txt_cassa_avere,
                 txt_banca_dare, txt_banca_avere,
                 txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              end
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_cassa_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              activate_field(txt_cassa_dare,
               txt_descrizione)
            else
              if scrittura.causale
                copy_field(txt_cassa_avere.view_data)
                activate_field(txt_banca_dare, txt_banca_avere,
                 txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              else
                activate_field(txt_banca_dare, txt_banca_avere,
                 txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              end
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_banca_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              activate_field(txt_cassa_avere, txt_cassa_dare,
                              txt_descrizione)
            else
              if scrittura.causale
                copy_field(txt_banca_dare.view_data)
                activate_field(txt_banca_avere,
                 txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              else
                activate_field(txt_banca_avere,
                 txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              end
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_banca_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              activate_field(txt_banca_dare, txt_cassa_avere,
                              txt_cassa_dare, txt_descrizione)
            else
              if scrittura.causale
                copy_field(txt_banca_avere.view_data)
                activate_field(txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              else
                activate_field(txt_fuori_partita_dare, txt_fuori_partita_avere,
                 btn_salva)
              end
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_fuori_partita_dare_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              activate_field(txt_banca_avere, txt_banca_dare,
                             txt_cassa_avere, txt_cassa_dare,
                             txt_descrizione)
            else
              if scrittura.causale
                copy_field(txt_fuori_partita_dare.view_data)
                activate_field(txt_fuori_partita_avere,
                 btn_salva)
              else
                activate_field(txt_fuori_partita_avere,
                 btn_salva)
              end
            end
          else
            evt.skip()
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def txt_fuori_partita_avere_keypress(evt)
        begin
          case evt.get_key_code
          when Wx::K_TAB
            if evt.shift_down()
              activate_field(txt_fuori_partita_dare, txt_banca_avere, txt_banca_dare,
                             txt_cassa_avere, txt_cassa_dare,
                             txt_descrizione)
            else
              if scrittura.causale
                copy_field(txt_fuori_partita_avere.view_data)
                activate_field(btn_salva)
              else
                activate_field(btn_salva)
              end
            end
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
          lku_banca.match_selection()
          btn_salva_click(evt)
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_causale_after_change()
        begin
          causale = lku_causale.match_selection()
          txt_descrizione.view_data = causale.descrizione_agg if causale
          collega_banca_alla causale
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
            if lku_banca.view_data.nil?
              collega_banca_alla causale
            end
          end
          transfer_scrittura_from_view()
          update_riga_ui()
        rescue Exception => e
          log_error(self, e)
        end

      end

      def lku_banca_after_change()
        begin
          lku_banca.match_selection()
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

                  if self.scrittura.con_importi_differenti?
                    res = Wx::message_box("Gli importi inseriti sono diffenrenti.\nContinuare?",
                      'Domanda',
                      Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

                    if res == Wx::NO
                      activate_field(txt_cassa_dare, txt_cassa_avere,
                       txt_banca_dare, txt_banca_avere,
                       txt_fuori_partita_dare, txt_fuori_partita_avere)
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
                      Wx::message_box("Inserire almeno un importo.",
                        'Info',
                        Wx::OK | Wx::ICON_INFORMATION, self)
                      activate_field(txt_cassa_dare, txt_cassa_avere,
                       txt_banca_dare, txt_banca_avere,
                       txt_fuori_partita_dare, txt_fuori_partita_avere)

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
            end
          end
        rescue Exception => e
          log_error(self, e)
        end

      end

      def reset_gestione_riga()
        reset_scrittura()
        causale = lku_causale.set_default()
        if(causale and causale.banca)
          lku_banca.match_selection(causale.banca.codice)
        else
          lku_banca.view_data = nil
        end
        txt_data_operazione.view_data = Date.today if txt_data_operazione.view_data.blank?
      end

      def scrittura_compatibile?
        if(!self.scrittura.causale_compatibile?)
          Wx::message_box("La causale non e' compatibile con la banca.",
            'Info',
            Wx::OK | Wx::ICON_INFORMATION, self)

          lku_causale.activate

          return false
        end

        # se alla scrittura e' associata una causale
        if(self.scrittura.causale)
          # che presuppone un movimento di banca
          if(self.scrittura.causale.movimento_di_banca?)
            # e la scrittura non ha una banca
            if(self.scrittura.banca.nil?)
              # chiedo di inserire una banca
              Wx::message_box("La causale selezionata presuppone un movimento di banca:\nselezionare la banca se esiste, oppure, configurarne una nel pannello 'configurazione -> azienda'.",
                'Info',
                Wx::OK | Wx::ICON_INFORMATION, self)

              lku_banca.activate

              return false
            end
          end
        else
          if(!self.scrittura.importo_compatibile?)
            Wx::message_box("L'importo non e' compatibile con la banca.",
              'Info',
              Wx::OK | Wx::ICON_INFORMATION, self)

            lku_banca.activate

            return false
          end
        end

        return true
      end

      def update_riga_ui()
        if self.scrittura.new_record?
          enable_widgets [txt_data_operazione, lku_causale,
                          lku_banca, txt_descrizione,
                          btn_salva, btn_nuova]
          disable_widgets [btn_elimina]
          toggle_fields()
        else
          if self.scrittura.esterna?
            disable_widgets [txt_data_operazione, lku_causale,
                            lku_banca, txt_descrizione,
                            txt_cassa_dare, txt_cassa_avere,
                            txt_banca_dare, txt_banca_avere,
                            txt_fuori_partita_dare, txt_fuori_partita_avere,
                            btn_salva, btn_elimina]
            enable_widgets [btn_nuova]
          else
            if self.scrittura.congelata?
              disable_widgets [txt_data_operazione, lku_causale,
                              lku_banca, txt_descrizione,
                              txt_cassa_dare, txt_cassa_avere,
                              txt_banca_dare, txt_banca_avere,
                              txt_fuori_partita_dare, txt_fuori_partita_avere,
                              btn_salva]
              enable_widgets [btn_elimina, btn_nuova]
            else
              enable_widgets [txt_data_operazione, lku_causale,
                              lku_banca, txt_descrizione,
                              btn_salva, btn_elimina, btn_nuova]
              toggle_fields()
            end
          end
        end
      end

      def toggle_fields()
        if causale = self.scrittura.causale
          causale.cassa_dare? ? enable_widgets([txt_cassa_dare]) : (disable_widgets([txt_cassa_dare]); txt_cassa_dare.view_data = nil)
          causale.cassa_avere? ? enable_widgets([txt_cassa_avere]) : (disable_widgets([txt_cassa_avere]); txt_cassa_avere.view_data = nil)
          causale.banca_dare? ? enable_widgets([txt_banca_dare]) : (disable_widgets([txt_banca_dare]); txt_banca_dare.view_data = nil)
          causale.banca_avere? ? enable_widgets([txt_banca_avere]) : (disable_widgets([txt_banca_avere]); txt_banca_avere.view_data = nil)
          causale.fuori_partita_dare? ? enable_widgets([txt_fuori_partita_dare]) : (disable_widgets([txt_fuori_partita_dare]); txt_fuori_partita_dare.view_data = nil)
          causale.fuori_partita_avere? ? enable_widgets([txt_fuori_partita_avere]) : (disable_widgets([txt_fuori_partita_avere]); txt_fuori_partita_avere.view_data = nil)
        else
          enable_widgets [txt_cassa_dare, txt_cassa_avere,
                         txt_banca_dare, txt_banca_avere,
                         txt_fuori_partita_dare, txt_fuori_partita_avere]

        end
      end

      def riepilogo_saldi()
        saldo_cassa = ctrl.saldo_cassa()
        saldo_banca = ctrl.saldo_banca()

        self.lbl_saldo_cassa.foreground_colour = ((saldo_cassa > 0) ? Wx::BLACK : Wx::RED)
        self.lbl_saldo_cassa.label = Helpers::ApplicationHelper.currency(saldo_cassa)

        self.lbl_saldo_banca.foreground_colour = ((saldo_banca > 0) ? Wx::BLACK : Wx::RED)
        self.lbl_saldo_banca.label = Helpers::ApplicationHelper.currency(saldo_banca)

      end

      def copy_field(importo)
        txt_cassa_avere.view_data = importo if scrittura.causale.cassa_avere?
        txt_banca_dare.view_data = importo if scrittura.causale.banca_dare?
        txt_banca_avere.view_data = importo if scrittura.causale.banca_avere?
        txt_fuori_partita_dare.view_data = importo if scrittura.causale.fuori_partita_dare?
        txt_fuori_partita_avere.view_data = importo if scrittura.causale.fuori_partita_avere?
      end

      def collega_banca_alla(causale)
        if(causale)
          # se alla causale e' associata una banca
          if(causale.banca)
            # visualizzo quella associata
            lku_banca.match_selection(causale.banca.codice)
          else
            # se la causale movimenta la banca
            if causale.movimento_di_banca?
              # se esiste una banca predefinita
              if lku_banca.default
                # visualizzo quella predefinita
                lku_banca.set_default()
              else
                # nel caso ci siano piu' banche attive,
                banche_attive = lku_banca.select_all {|banca| banca.attiva?}
                # gli associo l'unica banca attiva disponibile
                if banche_attive.length == 1
                  lku_banca.view_data = banche_attive.first
                # altrimenti viene chiesto all'utente
                else
                  lku_banca.view_data = nil
                end
              end
            else
              # la banca non viene impostata
              lku_banca.view_data = nil
            end
          end
        else
          # senza modalita di pagamento non viene impostata la banca
          lku_banca.view_data = nil
        end
      end

    end
  end
end
