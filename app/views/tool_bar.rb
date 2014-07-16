# encoding: utf-8

require 'app/views/base/base_panel'

module Views
  module ToolBar
    include Views::Base::Panel
    include Helpers::MVCHelper
    
    WXID_ESCI = 60001
    WXID_FKEY = 60002

    def ui
      
      controller :base
      
      logger.debug('initializing ToolBar...')
      xrc = Helpers::WxHelper::Xrc.instance()
      xrc.find('chce_azienda', self, :extends => ChoiceField) do |list|
        list.load_data(Models::Azienda.all, :label => :nome)
      end
      
      insert_separator(0)
      insert_tool(1, WXID_ESCI, '', 
        Helpers::ImageHelper.make_bitmap('exit.png'))
#        ,Helpers::ImageHelper.make_image('exit.png'), 
#        Wx::ITEM_NORMAL, 'Esci')
      evt_tool(WXID_ESCI) {|evt| btn_esci_click(evt)}
      insert_tool(5, WXID_FKEY, '', 
        Helpers::ImageHelper.make_bitmap('fn.png'))
#        ,Helpers::ImageHelper.make_image('exit.png'), 
#        Wx::ITEM_NORMAL, 'Esci')
      evt_tool(WXID_FKEY) {|evt| btn_key_click(evt)}
      realize()
      
      map_events(self)
 
      subscribe(:evt_azienda_updated) do
        init_panel()
      end

    end

    def init_panel()
      chce_azienda.view_data = Models::Azienda.current.id
    end
    
    def chce_azienda_select(evt)
      old_one = Models::Azienda.current.id
      Models::Azienda.current = ctrl.load_azienda(chce_azienda.view_data)
      process_event(Views::Base::CustomEvent::AziendaChangedEvent.new(old_one))
    end

    def btn_esci_click(evt)
      res = Wx::message_box("Confermi di voler uscire dal programma?",
        'Domanda',
        Wx::YES | Wx::NO | Wx::ICON_QUESTION, self)

      if res == Wx::YES
        Wx::get_app.exit_main_loop()
      end

    end

    def btn_key_click(evt)
      logger.debug('key button pressed')
      Wx::TipWindow.new(self,
                  "TASTI FUNZIONE\n\n" <<
                  "- F2   Focus lista\n" <<
                  "- F3   Variazione\n" <<
                  "- F5   Ricerca report/contestuale\n" <<
                  "- F6   Cliente\n" <<
                  "- F7   Fornitore\n" <<
                  "- F8   Salva\n" <<
                  "- F9   Stampa\n" <<
                  "- F10  Elimina\n" <<
                  "- F11  Parziale\n" <<
                  "- F12  Nuovo/Pulisci\n"
                  )
    end
  end
end