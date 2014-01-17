# encoding: utf-8

require 'app/controllers/account_controller'

module Views
  module Dialog
    class LoginDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()

        controller :account

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "LOGIN_DLG")

        # user interface
        xrc.find('txt_nome_utente', self, :extends => TextField)
        txt_nome_utente.set_focus()
        xrc.find('txt_password', self, :extends => TextField)
        xrc.find('lbl_messaggio_errore', self)
        lbl_messaggio_errore.foreground_colour = Wx::RED
        xrc.find('chce_azienda', self, :extends => ChoiceField)
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        xrc.find('wxID_CANCEL', self, :extends => CancelStdButton)
        wxid_ok.set_default()

        Azienda.all.each do |azienda|
          chce_azienda.append(azienda.nome, azienda.id)
        end

        if Models::Azienda.current
          chce_azienda.view_data = Models::Azienda.current.id
        else
          chce_azienda.select(0)
        end

        map_events(self)
        
        #evt_button(Wx::ID_OK) {|evt| validate_account(evt) }
        
        #evt_button(Wx::ID_CANCEL) {|event| Wx::get_app.exit_main_loop() }
        #WxHelper::map_events(self)
        #WxHelper::map_text(self, ['@txtfilterfrom', '@txtfilterto', '@txtfilterdescription'])
        #WxHelper::map_text(self, ['@txtinvoicesums'])

      end

      def btn_ok_click(evt)
        if ctrl.login(:user => txt_nome_utente.value,
                       :password => txt_password.value,
                       :azienda => chce_azienda.item_data(chce_azienda.selection()))
        else
          lbl_messaggio_errore.label = 'Nome utente o password errati'
          txt_nome_utente.activate()
          
          return
        end      
  
        evt.skip()
      end
    end
  end
end
