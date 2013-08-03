# encoding: utf-8

require 'app/helpers/image_helper'

module Views
  module Base
    module Widget
      module TextField
        def view_data=(data)
          data ? self.change_value(data.to_s) : self.change_value('')
        end
      
        def view_data()
          self.value
        end
				
        def activate()
          self.set_selection(-1, -1)
          self.set_focus()
				
        end

        def TextField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_loose_focus').to_sym) if mod.parent.respond_to?((mod.get_name() << '_loose_focus'))
            evt.skip()
          end

        end

      end

      module ImageLogoField
        attr_accessor :data
        
        def view_data=(data)
          self.data = data
          if data
            filename = File.join(Helpers::ApplicationHelper::WXBRA_IMAGES_PATH, ('logo.' << self.parent.dati_azienda.logo_tipo))
            open(filename, "wb") {|io| io.write(data) }
            self.set_bitmap(Wx::Bitmap.new(filename, Wx::BITMAP_TYPE_ANY))
          end
        end
      
        def view_data()
          self.data
        end
				
      end

      module LookupTextField
        include TextField
        def LookupTextField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_LOOKUP_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_loose_focus').to_sym) if mod.parent.respond_to?((mod.get_name() << '_loose_focus'))
            evt.skip()
          end
          mod.tool_tip = 'Premere F5 per la ricerca'
        end

      end

      module NumericField
        def view_data=(data)
          data ? self.change_value(data.to_s) : self.change_value('')
        end
      
        def view_data()
          self.value.to_i
        end

        def activate()
          self.set_selection(-1, -1)
          self.set_focus()
				
        end
				
        def NumericField.extended(mod)
          mod.evt_set_focus { mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_loose_focus').to_sym) if mod.parent.respond_to?((mod.get_name() << '_loose_focus'))
            evt.skip()
          end

          mod.instance_eval %{

            self.validator = Wx::TextValidator.new(Wx::FILTER_NUMERIC)

          }

        end
      end

      # mantiene il tipo di dato (testo) con il vincolo numerico
      # necessario per i Dirty object
      module TextNumericField
        def view_data=(data)
          data ? self.change_value(data.to_s) : self.change_value('')
        end
      
        def view_data()
          self.value
        end

        def activate()
          self.set_selection(-1, -1)
          self.set_focus()
				
        end
				
        def TextNumericField.extended(mod)
          mod.evt_set_focus { mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_loose_focus').to_sym) if mod.parent.respond_to?((mod.get_name() << '_loose_focus'))
            evt.skip()
          end

          mod.instance_eval %{

            self.validator = Wx::TextValidator.new(Wx::FILTER_NUMERIC)

          }

        end
      end

      module DecimalField
        def view_data=(data)
          data ? self.change_value(Helpers::ApplicationHelper.number_text(data)) : self.change_value('0')
        end
      
        def view_data()
          self.value.to_f
        end

        def activate()
          self.set_selection(-1, -1)
          self.set_focus()
				
        end
				
        def DecimalField.extended(mod)
          mod.evt_set_focus { mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_loose_focus').to_sym) if mod.parent.respond_to?((mod.get_name() << '_loose_focus'))
            evt.skip()
          end


          mod.instance_eval %{

            self.validator = Wx::TextValidator.new(Wx::FILTER_NUMERIC)

          }

        end
      end

      module ChoiceField
        def view_data=(data)
          self.selection = self.find_item_data(data)
        end
      
        def view_data()
          self.item_data(self.selection())
        end
        
        def find_item_data(data)
          0.upto(self.count - 1) do |i|
            if self.item_data(i) == data
              return i
            end
          end
          
          -1
        end
      
        def activate()
          self.set_focus()
				
        end
        
        def load_data(data, options={:label => :descrizione})
          self.clear()
          self.instance_hash.clear()
          if options[:include_blank]
            append(options[:include_blank][:label], nil)
          end
          data.each do |d|
            if options[:if]
              append(d[options[:label]].to_s, d[:id]) if options[:if].call(d)
            else
              append(d[options[:label]].to_s, d[:id])
            end
            self.instance_hash[d[:id]] = d
          end
          
          unless self.empty?
            case options[:select]
            when nil
            when :first
              self.select_first()
            when :last
              self.select_last()
            else
              self.select(options[:select])
            end
          end
        end
				
        def select_first()
          self.select(0)
        end

        def select_last()
          self.select(self.count() - 1)
        end

        def ChoiceField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_select'
              def #{mod.get_name()}_select(evt)
                  evt.skip()
              end
            end

          }

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@instance_hash, {})

            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
          }

        end

      end

      module ChoiceBooleanField
        include ChoiceField
        
        def load_data(data, options={:label => :descrizione})
          self.clear()
          self.instance_hash.clear()
          if options[:include_blank]
            append(options[:include_blank][:label], nil)
          end
          data.each do |d|
            if options[:if]
              append(d[0], d[1]) if options[:if].call(d)
            else
              append(d[0], d[1])
            end
          end
          
          unless self.empty?
            case options[:select]
            when nil
            when :first
              self.select_first()
            when :last
              self.select_last()
            else
              self.select(options[:select])
            end
          end
        end
				
        def select_first()
          self.select(0)
        end

        def select_last()
          self.select(self.count() - 1)
        end

        def ChoiceBooleanField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_select'
              def #{mod.get_name()}_select(evt)
                  evt.skip()
              end
            end

          }

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@instance_hash, {})

            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
          }

        end

      end

      module ChoiceObjectField
        include ChoiceField
	
        def load_data(data, options={:label => :descrizione})
          self.clear()
          self.instance_hash.clear()
          if options[:include_blank]
            append(options[:include_blank][:label], nil)
          end
          data.each do |d|
            if options[:if]
              append(d[options[:label]].to_s, d) if options[:if].call(d)
            else
              append(d[options[:label]].to_s, d)
            end
            instance_hash[d[:id]] = d
          end

          unless self.empty?
            case options[:select]
            when nil
            when :first
              self.select_first()
            when :last
              self.select_last()
            else
              self.select(options[:select])
            end
          end
        end
				
        def ChoiceObjectField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_select'
              def #{mod.get_name()}_select(evt)
                  evt.skip()
              end
            end

          }

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@instance_hash, {})

            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
          }

        end

      end

      module ChoiceStringField
        include ChoiceField
        
        def view_data=(data)
          self.string_selection = data.to_s
        end
      
        def view_data()
          self.string_selection()
        end
        
        def load_data(data, options={})
          self.clear()
          if options[:include_blank]
            append(options[:include_blank][:label])
          end
          if options[:if]
            self.append(data) if options[:if].call(data)
          else
            self.append(data)
          end
          
          unless self.empty?
            case options[:select]
            when nil
            when :first
              self.select_first()
            when :last
              self.select_last()
            else
              self.select(options[:select])
            end
          end
        end

        def ChoiceStringField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_select'
              def #{mod.get_name()}_select(evt)
                  evt.skip()
              end
            end

          }

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@instance_hash, {})

            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
          }

        end

      end

      module ComboField
        def view_data=(data)
          self.selection = self.find_item_data(data)
        end
      
        def view_data()
          self.item_data(self.selection())
        end
        
        def find_item_data(data)
          0.upto(self.count - 1) do |i|
            if self.item_data(i) == data
              return i
            end
          end
          
          -1
        end
      
        def activate()
          self.set_focus()
				
        end
      
        def match_selection()
          self.string_selection = self.get_value()
        end
        
        def load_data(data, options={:label => :descrizione})
          self.clear()
          self.instance_hash.clear()
          if options[:include_blank]
            append(options[:include_blank][:label], nil)
          end
          data.each do |d|
            if options[:if]
              append(d[options[:label]].to_s, d[:id]) if options[:if].call(d)
            else
              append(d[options[:label]].to_s, d[:id])
            end
            self.instance_hash[d[:id]] = d
          end
          
          unless self.empty?
            case options[:select]
            when nil
            when :first
              self.select_first()
            when :last
              self.select_last()
            else
              self.select(options[:select])
            end
          end
        end
				
        def select_first()
          self.select(0)
        end

        def select_last()
          self.select(self.count() - 1)
        end

        def ComboField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # in xrc non funziona il flag TE_PROCESS_ENTER
          # se lo abilito programmaticamente, viene disabilitata la combinazione di tasti 'shift-tab'
          # la gestione viene reimplementata sotto
          mod.toggle_window_style(Wx::TE_PROCESS_ENTER)
          
          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_select'
              def #{mod.get_name()}_select(evt)
                  evt.skip()
              end
            end

            # change event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_change'
              def #{mod.get_name()}_change(evt)
                  evt.skip()
              end
            end

            # enter event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_enter'
              def #{mod.get_name()}_enter(evt)
                #{mod.get_name()}.match_selection()
                evt.skip()
              end
            end

            # tab_keypress event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_keypress'
              def #{mod.get_name()}_keypress(evt)
                case evt.get_key_code
                when Wx::K_TAB
                  if evt.get_modifiers() == Wx::MOD_SHIFT
                    #{mod.get_name()}.navigate(0)
                  else
                    #{mod.get_name()}.navigate()
                  end
                when Wx::K_RETURN
                  self.#{mod.get_name()}_enter(evt)
                else
                  evt.skip()
                end
              end
            end

          }

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@instance_hash, {})

            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
          }

        end

      end

      module ComboObjectField
        include ComboField
	
        def load_data(data, options={:label => :descrizione})
          self.clear()
          self.instance_hash.clear()
          if options[:include_blank]
            append(options[:include_blank][:label], nil)
          end
          data.each do |d|
            if options[:if]
              append(d[options[:label]].to_s, d) if options[:if].call(d)
            else
              append(d[options[:label]].to_s, d)
            end
            instance_hash[d[:id]] = d
          end

          unless self.empty?
            case options[:select]
            when nil
            when :first
              self.select_first()
            when :last
              self.select_last()
            else
              self.select(options[:select])
            end
          end
        end
				
        def ComboObjectField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # in xrc non funziona il flag TE_PROCESS_ENTER
          # se lo abilito programmaticamente, viene disabilitata la combinazione di tasti 'shift-tab'
          # la gestione viene reimplementata sotto
          mod.toggle_window_style(Wx::TE_PROCESS_ENTER)
          
          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{


            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_select'
              def #{mod.get_name()}_select(evt)
                  evt.skip()
              end
            end

            # change event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_change'
              def #{mod.get_name()}_change(evt)
                  evt.skip()
              end
            end

            # enter event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_enter'
              def #{mod.get_name()}_enter(evt)
                #{mod.get_name()}.match_selection()
                evt.skip()
              end
            end

            # tab_keypress event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_keypress'
              def #{mod.get_name()}_keypress(evt)
                case evt.get_key_code
                when Wx::K_TAB
                  if evt.get_modifiers() == Wx::MOD_SHIFT
                    #{mod.get_name()}.navigate(0)
                  else
                    #{mod.get_name()}.navigate()
                  end
                when Wx::K_RETURN
                  self.#{mod.get_name()}_enter(evt)
                else
                  evt.skip()
                end
              end
            end

          }

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@instance_hash, {})

            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
          }

        end

      end

      module ComboStringField
        include ComboField
        
        def view_data=(data)
          self.string_selection = data.to_s
        end
      
        def view_data()
          self.string_selection()
        end
        
        def load_data(data, options={})
          self.clear()
          if options[:include_blank]
            append(options[:include_blank][:label])
          end
          if options[:if]
            self.append(data) if options[:if].call(data)
          else
            self.append(data)
          end
          
          unless self.empty?
            case options[:select]
            when nil
            when :first
              self.select_first()
            when :last
              self.select_last()
            else
              self.select(options[:select])
            end
          end
        end

        def ComboStringField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # in xrc non funziona il flag TE_PROCESS_ENTER
          # se lo abilito programmaticamente, viene disabilitata la combinazione di tasti 'shift-tab'
          # la gestione viene reimplementata sotto
          mod.toggle_window_style(Wx::TE_PROCESS_ENTER)
          
          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_select'
              def #{mod.get_name()}_select(evt)
                  evt.skip()
              end
            end

            # change event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_change'
              def #{mod.get_name()}_change(evt)
                  evt.skip()
              end
            end

            # enter event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_enter'
              def #{mod.get_name()}_enter(evt)
                #{mod.get_name()}.match_selection()
                evt.skip()
              end
            end

            # tab_keypress event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_keypress'
              def #{mod.get_name()}_keypress(evt)
                case evt.get_key_code
                when Wx::K_TAB
                  if evt.get_modifiers() == Wx::MOD_SHIFT
                    #{mod.get_name()}.navigate(0)
                  else
                    #{mod.get_name()}.navigate()
                  end
                when Wx::K_RETURN
                  self.#{mod.get_name()}_enter(evt)
                else
                  evt.skip()
                end
              end
            end

          }

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@instance_hash, {})

            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
          }

        end

      end

      module LookupField
        attr_accessor :data
        
        def view_data=(data)
          data ? self.change_value(data.send(@info[:code]).to_s) : self.change_value('')
          @info[:label].call(data) if @info[:label]
          @data = data
        end
      
        def view_data()
          @data
        end
      
        def activate()
          self.set_selection(-1, -1)
          self.set_focus()
				
        end

        def LookupField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_LOOKUP_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_after_change').to_sym)
            evt.skip()
          end

          mod.tool_tip = 'Premere F5 per la ricerca'

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@code_hash, {})
            instance_variable_set(:@instance_hash, {})
            instance_variable_set(:@default, nil)

            # accessors utility
            def code_hash()
              @code_hash
            end

            def code_hash=(obj)
              @code_hash = obj
            end
            
            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
            # accessors utility
            def default()
              @default
            end

            def default=(obj)
              @default = obj
            end
            
          }

          mod.parent.instance_eval %{
          
            # enter event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_enter'
              def #{mod.get_name()}_enter(evt)
                #{mod.get_name()}.match_selection()
                evt.skip()
              end
            end

          }
          
        end

        # :model => il modello
        # :code => il codice da visualizzare
        # :desc => la descrizione da visualizzare
        # :dialog => la finestra di ricerca
        # :default => il default da impostare (predefinito/a o nil)
        def configure(info)
          @info = info
          self.parent.instance_eval %{

            # F5_keypress event handler
            unless self.respond_to? '#{self.get_name()}_keypress'
              def #{self.get_name()}_keypress(evt)
                begin
                  case evt.get_key_code
                  when Wx::K_F5
                    dlg = Views::Dialog::#{@info[:dialog].to_s.camelize}.new(self)
                    dlg.center_on_screen(Wx::BOTH)
                    answer = dlg.show_modal()
                    if answer == Wx::ID_OK
                      #{self.get_name()}.view_data = ctrl.load_#{@info[:model]}(dlg.selected)
                      #{self.get_name()}_after_change()
                    elsif((dlg.respond_to?('btn_nuovo') && (answer == dlg.btn_nuovo.get_id)) ||
                      (dlg.respond_to?('btn_nuova') && (answer == dlg.btn_nuova.get_id)))
                      evt_new = Views::Base::CustomEvent::NewEvent.new(:#{@info[:model]}, [#{@info[:view]}, #{@info[:folder]}])
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
            end

            unless self.respond_to? '#{self.get_name()}_after_change'
              def #{self.get_name()}_after_change()
                #{self.get_name()}.match_selection()
              end

            end

          }

        end
        
        def load_data(data)
          self.code_hash.clear()
          self.instance_hash.clear()
          self.default = nil
          data.each do |d|
            self.code_hash[d.send(@info[:code])] = d
            self.instance_hash[d[:id]] = d
            self.default = d if @info[:default].call(d)
          end
        end
        
        def set_default
          self.view_data = self.default 
        end

        def match_selection(code=nil)
          self.view_data = (code ? code_hash[code] : code_hash[self.value])
        end
        
        def select_all(&block)
          self.instance_hash.values.select do |item|
            block.call(item)
          end
        end
        
      end

      # permette di chiamare due metodi diversi a socondo dell'azione
      # al cambio (F5) chiama il metodo *_after_change
      # alla perdita del focus chiama il metodo *_loose_focus
      module LookupLooseField
        include LookupField
        def LookupLooseField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_LOOKUP_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_loose_focus').to_sym) if mod.parent.respond_to?((mod.get_name() << '_loose_focus'))
            evt.skip()
          end
          
          mod.tool_tip = 'Premere F5 per la ricerca'

          mod.instance_eval %{

            # item_selected event handler
            instance_variable_set(:@code_hash, {})
            instance_variable_set(:@instance_hash, {})
            instance_variable_set(:@default, nil)

            # accessors utility
            def code_hash()
              @code_hash
            end

            def code_hash=(obj)
              @code_hash = obj
            end
            
            # accessors utility
            def instance_hash()
              @instance_hash
            end

            def instance_hash=(obj)
              @instance_hash = obj
            end
            
            # accessors utility
            def default()
              @default
            end

            def default=(obj)
              @default = obj
            end
            
          }

          mod.parent.instance_eval %{
          
            # enter event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_enter'
              def #{mod.get_name()}_enter(evt)
                #{mod.get_name()}.match_selection()
                evt.skip()
              end
            end

          }
          
        end

      end

      
      module ToggleLookupField
        attr_accessor :data
        
        def view_data=(data)
          self.value = (data ? true : false)
          @data = data
        end
      
        def view_data()
          @data
        end
      
      end

      module CheckField
        # data e' un valore booleano
        def view_data=(data)
          self.value = (data.nil? || (data == false) || (data == 0)) ? false : true
        end

        def view_data()
          self.value
        end

        def CheckField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_click'
              def #{mod.get_name()}_click(evt)
                  evt.skip()
              end
            end

          }

        end

      end

      module CheckListField
        # data è un array di stringhe
        def view_data=(data)
          self.set(data)
        end

        # ritorna gli indici degli elementi selezionati
        def view_data()
          self.get_checked_items()
        end

        def load_data(data, options={})
          labels = data.map do |d|
            case options[:label]
            when String, Symbol
              d.send(options[:label])
            when Proc
              options[:label].arity == 0 ? options[:label].call() : options[:label].call(d)
            else
              'Missing label'
            end
          end
          self.view_data = labels
        end

        def CheckListField.extended(mod)

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_click'
              def #{mod.get_name()}_click(evt)
                  evt.skip()
              end
            end

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_dblclick'
              def #{mod.get_name()}_dblclick(evt)
                  evt.skip()
              end
            end

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_check'
              def #{mod.get_name()}_check(evt)
                  evt.skip()
              end
            end

          }

        end

        def reset()
          self.each {|i| self.check(i, false)}
        end

      end

      # NumberCheckField per i campi interi di una cifra
      # evita interferenze con il metodo changed?
      module NumberCheckField
        # data e' un valore booleano
        def view_data=(data)
          self.value = (data.nil? || (data == false) || (data == 0)) ? false : true
        end
      
        def view_data()
          (self.value ? 1 : 0)
        end
      
        def NumberCheckField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_click'
              def #{mod.get_name()}_click(evt)
                  evt.skip()
              end
            end

          }

        end

      end

      module FkCheckField
        
        attr_accessor :data
        
        # data punta ad una foreign key
        def view_data=(data)
          self.value = data.nil? ? false : true
          @data = data
        end
      
        def view_data()
          @data
        end
      
        def FkCheckField.extended(mod)

          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR; evt.skip() }

          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_click'
              def #{mod.get_name()}_click(evt)
                  evt.skip()
              end
            end

          }

        end

      end

      module DateField
        
        BRA_DATE_FORMAT = "%d/%m/%Y" unless const_defined? 'BRA_DATE_FORMAT'
        BRA_DATE_TEMPLATE = "--/--/----" unless const_defined? 'BRA_DATE_TEMPLATE'
        BRA_TRY_FORMATS = ['%d/%m/%Y', '%d%m%Y']  unless const_defined? 'BRA_TRY_FORMATS' #'%d/%m/%y',
        BRA_EPOCH = Date.civil(2000, 1, 1) unless const_defined? 'BRA_EPOCH'
        
        def view_data=(data)
          data.blank? ? self.change_value('') : self.change_value(data.to_s(:italian_date)) #self.change_value(Date.today.to_s(:italian_date))
        end
      
        def view_data()
          #self.value.to_date.to_s(:italian_date)
          try_to_parse(self.value)
        end
				
        def try_to_parse(s)
          parsed = nil

          case s
            
            # stringhe che iniziano minimo con un numero e un massimo 3
            # stringhe che iniziano con + seguito da un numero e un massimo 3
            # stringhe che iniziano con - seguito da un numero e un massimo 3
          when /^\d{1,3}$/, /^\+\d{1,3}$/, /^\-\d{1,3}$/
            parsed = Date.today + s.to_i

          else
            BRA_TRY_FORMATS.each do |format|
              begin
                parsed = Date.strptime(s, format)
                break
              rescue ArgumentError
              end
            end
            
          end

          if parsed && (parsed.year < BRA_EPOCH.year || parsed.year > 2050)
            parsed = nil
          end

          return parsed
        end

        def activate()
          self.set_selection(-1, -1)
          self.set_focus()

        end
				
        def DateField.extended(mod)
          mod.evt_set_focus { |evt| mod.background_colour = Helpers::ApplicationHelper::WXBRA_FOCUS_FIELD_COLOR; evt.skip() }
          mod.evt_kill_focus do |evt| 
            mod.background_colour = Helpers::ApplicationHelper::WXBRA_FIELD_COLOR;
            mod.parent.send((mod.get_name() << '_loose_focus').to_sym) if mod.parent.respond_to?((mod.get_name() << '_loose_focus'))
            evt.skip()
          end

          mod.parent.instance_eval %{

            unless self.respond_to? '#{mod.get_name()}_loose_focus'
              def #{mod.get_name()}_loose_focus()
                #{mod.get_name()}.view_data = #{mod.get_name()}.view_data
              end

            end

          }

        end
      end

      module OkStdButton
        # noop
      end
      
      module ReportField
        
        def ReportField.extended(mod)
          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # result_set
            instance_variable_set(:@result_set_#{mod.get_name()}, [])

            # debugger if '#{mod.get_name()}' == 'lstrep_clienti'

            # accessor methods
            def result_set_#{mod.get_name()}()
              @result_set_#{mod.get_name()}
            end

            def result_set_#{mod.get_name()}=(obj)
              @result_set_#{mod.get_name()} = obj
            end

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_item_selected'
              def #{mod.get_name()}_item_selected(evt)
                #logger.debug('Item selected!')
                begin
                  @selected = evt.get_item().get_data()
                  if(#{mod.get_name()}.get_selected_item_count() > 1)
                    (@all_selections ||= []) << @selected if @selected
                  else
                    (@all_selections = []) << @selected if @selected
                  end
                rescue Exception => e
                  log_error(e)
                end

              end
            end

            # item_deselected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_item_deselected'
              def #{mod.get_name()}_item_deselected(evt)
                #noop
              end
            end

            # item_activated event handler
            if mod.parent.is_a? Dialog

              unless mod.parent.respond_to? '#{mod.get_name()}_item_activated'
                def #{mod.get_name()}_item_activated(evt)
                  #logger.debug('Item activated!')
                  begin
                    end_modal(Wx::ID_OK)
                  rescue Exception => e
                    log_error(e)
                  end
                end
              end
              
            else

              unless mod.parent.respond_to? '#{mod.get_name()}_item_activated'
                def #{mod.get_name()}_item_activated(evt)
                  #logger.debug('Item activated!')
                  evt.skip()
                end
              end

            end

          }

        end

        # riceve un array di hash che identificano 
        # le intestazioni delle colonne
        def column_info(info)
          clear_all()
          info.each_with_index do |i, idx|
            self.insert_column(idx, 
              i[:caption], 
              (i[:align] || Wx::LIST_FORMAT_LEFT),
              (i[:width] || Wx::LIST_AUTOSIZE_USEHEADER))
#              (i[:width] || Wx::LIST_AUTOSIZE))
            #self.set_column_width(idx, i[:width] || Wx::LIST_AUTOSIZE_USEHEADER)
          end
          
        end
      
        # riceve un array di symbol che identificano 
        # i campi del modello da visualizzare
        def data_info(info)
#          raise "Il numero di dati da visualizzare non corrisponde alle colonne" if info.size != self.column_count
#          imgList = Wx::ImageList.new(16,16)
#          flag = Helpers::ImageHelper.make_image('tick.png', 16)
#          imgList.add(Wx::Bitmap.new(flag))
#          self.set_image_list(imgList, Wx::IMAGE_LIST_SMALL)
          @data_info = info
        end
        
        def display(data, opts = {})
          reset()
          unless data.empty?
            idx = 0
            data.each do |model|
              insert_item(idx, '')
              set_item_data(idx, model[:id])
              @data_info.each_with_index do |info, col|
                case info[:format]
                  when nil
                    if info[:if]
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s) if info[:if].call(model)
                    else
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s)
                    end
#                  when :flag
#                    get_item(idx, col).set_image(0) if cast_eval(model, info[:attr])
#                    #set_item_column_image(idx, col, 0) if cast_eval(model, info[:attr])
                  when :currency
                    if info[:if]
                      set_item(idx, col, Helpers::ApplicationHelper.currency(cast_eval(model, info[:attr]))) if info[:if].call(model)
                    else
                      set_item(idx, col, Helpers::ApplicationHelper.currency(cast_eval(model, info[:attr])))
                    end
                  when :percentage
                    if info[:if]
                      set_item(idx, col, Helpers::ApplicationHelper.percentage(cast_eval(model, info[:attr]))) if info[:if].call(model)
                    else
                      set_item(idx, col, Helpers::ApplicationHelper.percentage(cast_eval(model, info[:attr])))
                    end
                  when :date                  
                    if info[:if]
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s(:italian_date)) if info[:if].call(model)
                    else
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s(:italian_date))
                    end
                  else
                    if info[:if]
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s) if info[:if].call(model)
                    else
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s)
                    end
                end
              end
              set_item_background_colour(idx, Helpers::ApplicationHelper::WXBRA_EVEN_ROW_COLOR) if idx.even? # 215, 235, 245
              idx += 1
            end
            unless opts[:ignore_focus]
              set_item_state(0, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED)
              set_focus()
            end
          end          
        end
	
        def display_matrix(matrix)
          reset()
          unless matrix.empty?
            matrix.each_with_index do |vector, row|
              insert_item(row, '')
              set_item_data(row, vector.ident) if vector.respond_to? 'ident'
              @data_info.each_with_index do |info, col|
                case info[:format]
                when nil
                  if info[:if]
                    set_item(row, col, matrix_cast_eval(vector[col], info[:attr]).to_s) if info[:if].call(vector[col])
                  else
                    set_item(row, col, matrix_cast_eval(vector[col], info[:attr]).to_s)
                  end
                when :currency
                  if info[:if]
                    set_item(row, col, Helpers::ApplicationHelper.currency(matrix_cast_eval(vector[col], info[:attr]))) if info[:if].call(vector[col])
                  else
                    set_item(row, col, Helpers::ApplicationHelper.currency(matrix_cast_eval(vector[col], info[:attr])))
                  end
                when :percentage
                  if info[:if]
                    set_item(row, col, Helpers::ApplicationHelper.percentage(matrix_cast_eval(vector[col], info[:attr]))) if info[:if].call(vector[col])
                  else
                    set_item(row, col, Helpers::ApplicationHelper.percentage(matrix_cast_eval(vector[col], info[:attr])))
                  end
                when :date                  
                  if info[:if]
                    set_item(row, col, matrix_cast_eval(vector[col], info[:attr]).to_s(:italian_date)) if info[:if].call(vector[col])
                  else
                    set_item(row, col, matrix_cast_eval(vector[col], info[:attr]).to_s(:italian_date))
                  end
                else
                  if info[:if]
                    set_item(row, col, matrix_cast_eval(vector[col], info[:attr]).to_s) if info[:if].call(vector[col])
                  else
                    set_item(row, col, matrix_cast_eval(vector[col], info[:attr]).to_s)
                  end
                end
              end
              set_item_background_colour(row, Helpers::ApplicationHelper::WXBRA_EVEN_ROW_COLOR) if row.even? # 215, 235, 245
            end
            set_item_state(0, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED)
          end          
        end

        def display_style_matrix(matrix)
          reset()
          unless matrix.empty?
            matrix.each_with_index do |vector, row|
              insert_item(row, '')
              set_item_data(row, vector.ident) if vector.respond_to? 'ident'
#              ident_list_item = Wx::ListItem.new
#              ident_list_item.set_data(vector.ident) if vector.respond_to? 'ident'
#              insert_item(ident_list_item)
              @data_info.each_with_index do |info, col|
                li = Wx::ListItem.new
                li.set_id(row)
                li.set_column(col)
                case info[:format]
                when nil
                  if info[:if]
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(matrix_cast_eval(vector[col], info[:attr]).to_s) if info[:if].call(vector[col])
                    set_item(li)
                  else
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(matrix_cast_eval(vector[col], info[:attr]).to_s)
                    set_item(li)
                  end
                when :currency
                  if info[:if]
                    li.set_text_colour(Wx::RED)
                    li.set_text(Helpers::ApplicationHelper.currency(matrix_cast_eval(vector[col], info[:attr]))) if info[:if].call(vector[col])
                    set_item(li)
                  else
                    li.set_text_colour(Wx::RED)
                    li.set_text(Helpers::ApplicationHelper.currency(matrix_cast_eval(vector[col], info[:attr])))
                    set_item(li)
                  end
                when :percentage
                  if info[:if]
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(Helpers::ApplicationHelper.percentage(matrix_cast_eval(vector[col], info[:attr]))) if info[:if].call(vector[col])
                    set_item(li)
                  else
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(Helpers::ApplicationHelper.percentage(matrix_cast_eval(vector[col], info[:attr])))
                    set_item(li)
                  end
                when :date                  
                  if info[:if]
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(matrix_cast_eval(vector[col], info[:attr]).to_s(:italian_date)) if info[:if].call(vector[col])
                    set_item(li)
                  else
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(matrix_cast_eval(vector[col], info[:attr]).to_s(:italian_date))
                    set_item(li)
                  end
                else
                  if info[:if]
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(matrix_cast_eval(vector[col], info[:attr]).to_s) if info[:if].call(vector[col])
                    set_item(li)
                  else
#                    li.set_text_colour(Wx::BLACK)
                    li.set_text(matrix_cast_eval(vector[col], info[:attr]).to_s)
                    set_item(li)
                  end
                end
              end
              set_item_background_colour(row, Helpers::ApplicationHelper::WXBRA_EVEN_ROW_COLOR) if row.even? # 215, 235, 245
            end
            set_item_state(0, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED)
          end          
        end

        def reset()
          delete_all_items()
        end

        def force_visible(sym)
          case sym
          when :first
            self.ensure_visible(0) if self.item_count > 0
          when :last
            self.ensure_visible(self.item_count - 1) if self.item_count > 0
          end
        end
        
        def force_selected(sym)
          case sym
          when :first
            self.set_item_state(0, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED) if self.item_count > 0
          when :last
            self.set_item_state(self.item_count - 1, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED) if self.item_count > 0
          end
        end

        private
        
        def cast_eval(model, attr)
          case attr
          when String, Symbol
            model.send(attr)
          when Proc
            attr.arity == 0 ? attr.call() : attr.call(model)
          end
        end

        def matrix_cast_eval(model, attr)
          case attr
          when String, Symbol
            model
          when Proc
            attr.arity == 0 ? attr.call() : attr.call(model)
          end
        end

        # comportamento comune a tutte le liste
        # da valutare
        #~ def lstrep_item_selected(evt)
        #~ if(@lstrep.get_selected_item_count() > 0)
        #~ @selected = evt.get_item().get_data()
        #~ end
        #~ end
				
      end

      module MultiSelReportField
        include ReportField
        
        def MultiSelReportField.extended(mod)
          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # result_set
            instance_variable_set(:@result_set_#{mod.get_name()}, [])

            # accessor methods
            def result_set_#{mod.get_name()}()
              @result_set_#{mod.get_name()}
            end

            def result_set_#{mod.get_name()}=(obj)
              @result_set_#{mod.get_name()} = obj
            end

            def #{mod.get_name()}_item_selected(evt)
              #logger.debug('Item selected!')
              begin
                #logger.debug('selected item: ' + evt.get_item().get_data().to_s)
                id = evt.get_item().get_data()[:id] rescue nil
                if(#{mod.get_name()}.get_selected_item_count() > 1)
                  (@all_selections ||= {})[id] = evt.get_item().get_data()
                else
                  (@all_selections = {})[id] = evt.get_item().get_data()
                end
                #logger.debug('all selections: ' + @all_selections.keys.join(','))
              rescue Exception => e
                log_error(e)
              end

            end

            def #{mod.get_name()}_item_deselected(evt)
              #logger.debug('Item deselected!')
              begin
                #logger.debug('deselected item: ' + evt.get_item().get_data().to_s)
                @all_selections.delete((evt.get_item().get_data()[:id] rescue nil))
                #logger.debug('all selections: ' + @all_selections.keys.join(','))
              rescue Exception => e
                log_error(e)
              end

            end

            # item_activated event handler
            if mod.parent.is_a? Dialog

              unless mod.parent.respond_to? '#{mod.get_name()}_item_activated'
                def #{mod.get_name()}_item_activated(evt)
                  #logger.debug('Item activated!')
                  begin
                    end_modal(Wx::ID_OK)
                  rescue Exception => e
                    log_error(e)
                  end
                end
              end

            else

              unless mod.parent.respond_to? '#{mod.get_name()}_item_activated'
                def #{mod.get_name()}_item_activated(evt)
                  #logger.debug('Item activated!')
                  evt.skip()
                end
              end

            end

          }

        end

      end

      module EditableReportField
        
        def EditableReportField.extended(mod)
          # crea il gestore di evento per l'elemento selezionato
          mod.parent.instance_eval %{

            # result_set
            instance_variable_set(:@result_set_#{mod.get_name()}, [])

            # debugger if '#{mod.get_name()}' == 'lstrep_maxi_incassi'

            # accessor methods
            def result_set_#{mod.get_name()}()
              @result_set_#{mod.get_name()}
            end

            def result_set_#{mod.get_name()}=(obj)
              @result_set_#{mod.get_name()} = obj
            end

            # item_selected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_item_selected'
              def #{mod.get_name()}_item_selected(evt)
                #logger.debug('Item selected!')
                begin
                  @selected = evt.get_item().get_data()
                rescue Exception => e
                  log_error(e)
                end

              end
            end

            # item_deselected event handler
            unless mod.parent.respond_to? '#{mod.get_name()}_item_deselected'
              def #{mod.get_name()}_item_deselected(evt)
                #noop
              end
            end

            # item_activated event handler
            if mod.parent.is_a? Dialog

              unless mod.parent.respond_to? '#{mod.get_name()}_item_activated'
                def #{mod.get_name()}_item_activated(evt)
                  #logger.debug('Item activated!')
                  begin
                    end_modal(Wx::ID_OK)
                  rescue Exception => e
                    log_error(e)
                  end
                end
              end
              
            else

              unless mod.parent.respond_to? '#{mod.get_name()}_item_activated'
                def #{mod.get_name()}_item_activated(evt)
                  #logger.debug('Item activated!')
                  evt.skip()
                end
              end

            end

#            unless mod.parent.respond_to? '#{mod.get_name()}_key_down'
#              def #{mod.get_name()}_key_down(evt)
#                #logger.debug('Key down!')
#                evt.skip()
#              end
#            end

          }

        end

        # riceve un array di hash che identificano 
        # le intestazioni delle colonne
        def column_info(info)
          clear_all()
          info.each_with_index do |i, idx|
            self.insert_column(idx, 
              i[:caption], 
              (i[:align] || Wx::LIST_FORMAT_LEFT),
              (i[:width] || Wx::LIST_AUTOSIZE_USEHEADER))
#              (i[:width] || Wx::LIST_AUTOSIZE))
            #self.set_column_width(idx, i[:width] || Wx::LIST_AUTOSIZE_USEHEADER)
          end
          
        end
      
        # riceve un array di symbol che identificano 
        # i campi del modello da visualizzare
        def data_info(info)
#          raise "Il numero di dati da visualizzare non corrisponde alle colonne" if info.size != self.column_count
          @data_info = info
        end

        def activate()
          if self.item_count > 0
            set_item_state(0, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED)
            set_focus()
          end
        end
        
        def display(data)
          reset()
          unless data.empty?
            idx = 0
            data.each do |model|
              if model.valid_record?
                insert_item(idx, '')
                set_item_data(idx, model.ident())
                @data_info.each_with_index do |info, col|
                  case info[:format]
                  when nil
                    if info[:if]
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s) if info[:if].call(model)
                    else
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s)
                    end
                  when :currency
                    if info[:if]
                      set_item(idx, col, Helpers::ApplicationHelper.currency(cast_eval(model, info[:attr]))) if info[:if].call(model)
                    else
                      set_item(idx, col, Helpers::ApplicationHelper.currency(cast_eval(model, info[:attr])))
                    end
                  when :percentage
                    if info[:if]
                      set_item(idx, col, Helpers::ApplicationHelper.percentage(cast_eval(model, info[:attr]))) if info[:if].call(model)
                    else
                      set_item(idx, col, Helpers::ApplicationHelper.percentage(cast_eval(model, info[:attr])))
                    end
                  when :date                  
                    if info[:if]
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s(:italian_date)) if info[:if].call(model)
                    else
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s(:italian_date))
                    end
                  else
                    if info[:if]
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s) if info[:if].call(model)
                    else
                      set_item(idx, col, cast_eval(model, info[:attr]).to_s)
                    end
                  end
                end
                set_item_background_colour(idx, Helpers::ApplicationHelper::WXBRA_EVEN_ROW_COLOR) if idx.even? # 215, 235, 245
                idx += 1
              end
            end
#            set_item_state(0, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED)
#            set_focus()
          end          
        end
	
        def reset()
          delete_all_items()
        end

        def force_visible(sym)
          case sym
          when :first
            self.ensure_visible(0) if self.item_count > 0
          when :last
            self.ensure_visible(self.item_count - 1) if self.item_count > 0
          end
        end

        def force_selected(sym)
          case sym
          when :first
            self.set_item_state(0, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED) if self.item_count > 0
          when :last
            self.set_item_state(self.item_count - 1, Wx::LIST_STATE_SELECTED, Wx::LIST_STATE_SELECTED) if self.item_count > 0
          end
        end

        private
        
        def cast_eval(model, attr)
          case attr
          when String, Symbol
            model.send(attr)
          when Proc
            attr.arity == 0 ? attr.call() : attr.call(model)
          end
        end
      end

      class ReportItem < Wx::ListItem
  
        def initialize(data, text, image=nil)
          super()
          set_data(data)
          set_text(text)
          set_bold_font()
          set_image(image) unless image.nil?
        end
  
        def set_bold_font()
          self.set_font(Wx::Font.new(10, 
              Wx::FONTFAMILY_DEFAULT,
              Wx::FONTSTYLE_NORMAL,
              Wx::FONTWEIGHT_NORMAL))
        end
      end
      
    end
  end
end