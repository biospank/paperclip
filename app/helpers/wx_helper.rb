# encoding: utf-8

require 'singleton'

module Helpers
  module WxHelper
    class Xrc
      include Singleton
      include Helpers::Logger

      attr_reader :resource

      def initialize
        @resource = Wx::XmlResource.get
        #@resource.add_handler(WxArchiveFSHandler.new)
        @resource.flags = 2 # Wx::XRC_NO_SUBCLASSING
        @resource.init_all_handlers
        #@resource.load("resources/xrc/ui.xrc")
        @resource.load("resources/xrc/ui.xrs")

        @finder = lambda do | x, parent |
          Wx::Window.find_window_by_id(Wx::xrcid(x), parent)
        end

      end

      def find(x, parent, opt = {})
        widget = @finder.call(x, parent)
        widget.extend(opt[:extends]) if opt[:extends]
        #parent.instance_variable_set("@#{x}", widget)

        yield widget if block_given?

        # inizializzo la variabile d'istanza
        x.downcase!
        if opt[:force_parent]
          opt[:force_parent].instance_eval %{

            instance_variable_set('@#{x}', widget)

            # accessor methods
            def #{x}()
              @#{x}
            end

            def #{x}=(obj)
              @#{x} = obj
            end

          }

          if opt[:alias]
            opt[:force_parent].instance_eval %{
              alias #{opt[:alias]} #{x}
            }
          end

          widget.instance_eval %{

            instance_variable_set('@owner', opt[:force_parent])

            # reader method
            def owner()
              @owner
            end

          }

        else
          parent.instance_eval %{

            instance_variable_set('@#{x}', widget)

            # accessor methods
            def #{x}()
              @#{x}
            end

            def #{x}=(obj)
              @#{x} = obj
            end

          }

          if opt[:alias]
            parent.instance_eval %{
              alias #{opt[:alias]} #{x}
            }
          end

          widget.instance_eval %{

            instance_variable_set('@owner', parent)

            # reader method
            def owner()
              @owner
            end

          }

        end

        widget

      end

    end

#    def WxHelper.include_ui
#      ui = File.dirname(__FILE__) + "/../app/views/xrc"
#      Dir.foreach(ui) { |f|
#        load "#{ui}/#{f}" if f[-3..-1] == '.rb'
#      }
#    end

    def call_method(cls, m, evt)
      begin
        cls.method(m).call(evt)
      rescue ArgumentError => e
        logger.error e.message
        raise e
      rescue NameError => e
        logger.error e.message
        logger.error e.backtrace
        raise e
      end
    end

    def map_text(cls, txts)
      txts.each { |txt|
        obj = cls.instance_variable_get("@#{txt}")
        m = txt.gsub(/^(.*)$/, '\1_changed')
        cls.evt_text(obj) { |evt| call_method(cls, m, evt) }
      }
    end

    def map_text_enter(cls, txts)
      txts.each_pair { |txt, m|
        obj = cls.instance_variable_get("@#{txt}")
        cls.evt_text_enter(obj) { |evt| call_method(cls, m, evt) }
      }
    end

#    def map_text_focus(cls, txts)
#      txts.each { |txt|
#        obj = cls.instance_variable_get("@#{txt}")
#        m_focus = txt.gsub(/^(.*)$/, '\1_set_focus')
#        cls.evt_set_focus() { |evt| call_method(cls, m_focus, evt) }
#        m_kill_focus = txt.gsub(/^(.*)$/, '\1_kill_focus')
#        cls.evt_set_focus() { |evt| call_method(cls, m_kill_focus, evt) }
#      }
#    end

#    def map_text_enter(cls, txts)
#      txts.each { |txt|
#        obj = cls.instance_variable_get("@#{txt}")
#        m = txt.gsub(/^(.*)$/, '\1_enter')
#        cls.evt_text_enter(obj) { |evt| call_method(cls, m, evt) }
#      }
#    end

    def grid_event(cls, type, evt)
      @grids.each { |name, obj|
        if evt.get_event_object == obj
          call_method(cls, name+'_'+type, evt)
          break
        end
      }
    end

    def list_event(cls, type, evt)
      @lists.each { |name, obj|
        if evt.get_event_object == obj
          call_method(cls, name+'_'+type, evt)
          break
        end
      }
    end

    def map_events(cls)
      @grids = {} unless @grids
      @lists = {} unless @lists

      cls.instance_variables.each { |var|
        obj = cls.instance_variable_get(var)

        var = var.to_s

        case var
        when /^@btn/
          m = var.gsub(/^@(.*)$/, '\1_click')
          cls.evt_button(obj) { |evt| call_method(cls, m, evt) }

        when /^@tglbtn/
          m = var.gsub(/^@(.*)$/, '\1_click')
          cls.evt_togglebutton(obj) { |evt| call_method(cls, m, evt) }

        when /^@wxid_ok/
          cls.evt_button(obj) { |evt| call_method(cls, 'btn_ok_click', evt) }

        when /^@wxid_cancel/
          cls.evt_button(obj) { |evt| call_method(cls, 'btn_cancel_click', evt) }

        when /^@mnu/
          m = var.gsub(/^@(.*)$/, '\1_click')
          cls.evt_menu(obj) { |evt| call_method(cls, m, evt) }

        when /^@chklst/
          m = var.gsub(/^@(.*)$/, '\1')
          cls.evt_listbox(obj)        { |evt| call_method(cls, m+'_click',    evt) }
          cls.evt_listbox_dclick(obj) { |evt| call_method(cls, m+'_dblclick', evt) }
          cls.evt_checklistbox(obj) { |evt| call_method(cls, m+'_check', evt) }

        when /^@chk/
          m = var.gsub(/^@(.*)$/, '\1')
          cls.evt_checkbox(obj)  { |evt| call_method(cls, m+'_click', evt) }

        # List events
        when /^@lstrep/
          m = var.gsub(/^@(.*)$/, '\1')
          @lists[m] = obj
          cls.evt_list_item_selected(obj)    { |evt| list_event(cls, 'item_selected', evt) }
          cls.evt_list_item_deselected(obj)    { |evt| list_event(cls, 'item_deselected', evt) }
          cls.evt_list_item_activated(obj)    { |evt| list_event(cls, 'item_activated', evt) }
#          cls.evt_list_key_down(obj)    { |evt| list_event(cls, 'key_down', evt) }

        # Notebook events
        when /notebook_mgr$/
          m = var.gsub(/^@(.*)$/, '\1')
          cls.evt_notebook_page_changed(obj)    { |evt| call_method(obj, m+'_page_changed', evt) }
          cls.evt_notebook_page_changing(obj)    { |evt| call_method(obj, m+'_page_changing', evt) }

        when /^@lst/
          m = var.gsub(/^@(.*)$/, '\1')
          cls.evt_listbox(obj)        { |evt| call_method(cls, m+'_click',    evt) }
          cls.evt_listbox_dclick(obj) { |evt| call_method(cls, m+'_dblclick', evt) }

        when /^@cmb/
          m = var.gsub(/^@(.*)$/, '\1')
          cls.evt_combobox(obj)       { |evt| call_method(cls, m+'_select', evt) }
          cls.evt_text(obj)           { |evt| call_method(cls, m+'_change', evt) }
#          cls.evt_text_enter(obj)     { |evt| call_method(cls, m+'_enter',   evt) }
          obj.evt_char { |evt| call_method(cls, m+'_keypress',   evt) }
#          obj.connect(Wx::ID_ANY,
#                      Wx::ID_ANY,
#                      Wx::EVT_KEY_DOWN)   { |evt| call_method(cls, m+'_enter_keypress', evt) }

        when /^@lku/
          m = var.gsub(/^@(.*)$/, '\1')
          obj.evt_char { |evt| call_method(cls, m+'_keypress',   evt) }
          cls.evt_text_enter(obj)     { |evt| call_method(cls, m+'_enter',   evt) }

        when /^@chce/
          m = var.gsub(/^@(.*)$/, '\1')
          cls.evt_choice(obj) { |evt| call_method(cls, m+'_select', evt) }

        when /^@grid/
          m = var.gsub(/^@(.*)$/, '\1')
          @grids[m] = obj

        end

      }

      # Grid events
      cls.evt_grid_select_cell      { |evt| grid_event(cls, 'click',        evt) }
      cls.evt_grid_label_left_click { |evt| grid_event(cls, 'label_click',  evt) }
      cls.evt_grid_range_select     { |evt| grid_event(cls, 'range_select', evt) }

    end
  end
end
