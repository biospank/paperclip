require 'rbconfig'
# da scommentare per ruby 1.9
$ruby_version = RbConfig::CONFIG['ruby_version'].split('.').join.to_i
$:.unshift File.dirname(__FILE__) if $ruby_version > 186

begin
  require 'rubygems'
rescue LoadError
end

require 'app/config/environment'
require 'app/helpers/mvc_helper'
require 'app/controllers/base_controller'
require 'app/controllers/anagrafica_controller'
require 'app/views/base/widget'
require 'app/helpers/odf_helper'

include Wx

class AttestazioneFrame < Frame
  include Helpers::MVCHelper
  include Helpers::ODF::Report
  include Views::Base::Widget

  def initialize
    super()
    resource = Wx::XmlResource.get
    #@resource.add_handler(WxArchiveFSHandler.new)
    resource.flags = 2 # Wx::XRC_NO_SUBCLASSING
    resource.init_all_handlers
    #@resource.load("resources/xrc/ui.xrc")
    resource.load("resources/xrc/attestazione.xrs")

    @finder = lambda do | x, parent |
      Wx::Window.find_window_by_id(Wx::xrcid(x), parent)
    end

    resource.load_frame_subclass(self, nil, "attestazione")
    set_icon(Wx::Icon.new('resources/images/paperclip.ico', Wx::BITMAP_TYPE_ICO))
    ui()
  end

  def ui()
    model :filtro => {:attrs => []}
    controller :anagrafica
    
    logger.debug('initializing AttestazioneFrame...')
    find('chce_cliente', self, :extends => ChoiceField) do |field|
      field.load_data(Models::Cliente.find(:all, :conditions => 'azienda_id = 1', :order => 'denominazione'),
              :label => :denominazione,
              :if => lambda {|cliente| cliente.attivo? },
              :include_blank => {:label => 'Tutti'},
              :select => :first)

    end

    find('btn_compila', self)
    find('btn_esci', self)

    map_events(self)
    
  end

  def chce_cliente_select(evt)
    evt.skip()
  end

  def btn_esci_click(evt)
    Wx::get_app.exit_main_loop()
  end

  def btn_compila_click(evt)
    transfer_filtro_from_view()
    dlg = Wx::DirDialog.new(self, "Scegli una cartella di destinazione:")
    if dlg.show_modal() == Wx::ID_OK
      template = "resources/models/anagrafica/attestazione.odt"

      if (filtro.cliente)
        Wx::BusyCursor.busy() do
          cliente = Models::Cliente.find(filtro.cliente)
          dest = File.join(dlg.get_path(), cliente.denominazione.gsub(/\W/, ' ') + '.odt')
          generate(template, cliente, false, dest)
        end
      else
        clienti = Models::Cliente.find(:all, :conditions => 'azienda_id = 1 and attivo = 1', :order => 'denominazione')

        progress = Wx::ProgressDialog.new("Genarazione dei moduli di attestazione", "Avvio compilazione documento", clienti.size, self,
                                        Wx::PD_CAN_ABORT | Wx::PD_APP_MODAL)

        count = 1

        clienti.each do |cliente|
          progress.update(count, "Attestazione #{cliente.denominazione}")
          dest = File.join(dlg.get_path(), cliente.denominazione.gsub(/\W/, ' ') + '.odt')
          generate(template, cliente, false, dest)
          count += 1
        end

        progress.destroy()

      end

    end

  end

  def render_header(report, cliente=nil)
    dati_azienda = Models::Azienda.first.dati_azienda

    report.add_field :depo_denominazione, dati_azienda.denominazione
    report.add_field :depo_indirizzo, dati_azienda.indirizzo
    report.add_field :depo_cap, dati_azienda.cap
    report.add_field :depo_citta, dati_azienda.citta
    report.add_field :depo_codicefiscale, dati_azienda.cod_fisc
    report.add_field :depo_partitaiva, dati_azienda.p_iva
  end

  def render_body(report, cliente=nil)

  end

  def render_footer(report, cliente=nil)
    report.add_field :sogg_denominazione, cliente.denominazione
    report.add_field :sogg_indirizzo, cliente.indirizzo
    report.add_field :sogg_cap, cliente.cap
    report.add_field :sogg_comune, cliente.comune
    report.add_field :sogg_provincia, cliente.provincia
    report.add_field :sogg_codicefiscale, cliente.cod_fisc
    report.add_field :sogg_partitaiva, cliente.p_iva
    report.add_field :data_stampa, Date.today.to_s(:italian_date)
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
        opt[:force_parent].instance_eval %{
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

      when /^@chk/
        m = var.gsub(/^@(.*)$/, '\1')
        cls.evt_checkbox(obj)  { |evt| call_method(cls, m+'_click', evt) }

      # List events
      when /^@lstrep/
        m = var.gsub(/^@(.*)$/, '\1')
        @lists[m] = obj
        cls.evt_list_item_selected(obj)    { |evt| list_event(cls, 'item_selected', evt) }
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

class Attestazione < App

  def on_init

    begin
      attestazione = AttestazioneFrame.new
      attestazione.min_size = [0, 0]
      attestazione.show
    end

  end

end

Attestazione.new.main_loop

