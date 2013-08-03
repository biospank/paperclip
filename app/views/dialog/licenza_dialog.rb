# encoding: utf-8

require 'app/controllers/account_controller'

module Views
  module Dialog
    class LicenzaDialog < Wx::Dialog
      include Views::Base::Dialog
      include Helpers::MVCHelper
      include Models
      
      def initialize(parent)
        super()

        controller :base

        xrc = Xrc.instance()
        xrc.resource.load_dialog_subclass(self, parent, "LICENZA_DLG")

        # user interface
        xrc.find('txt_codice', self, :extends => TextField)
        txt_codice.set_focus()
        xrc.find('lbl_messaggio_errore', self)
        lbl_messaggio_errore.foreground_colour = Wx::RED
        xrc.find('wxID_OK', self, :extends => OkStdButton)
        wxid_ok.set_default()

        map_events(self)
        
      end

      def btn_ok_click(evt)
        begin
          hash = Digest::SHA1.hexdigest(Date.today.to_s(:italian_date))
          lic = txt_codice.view_data
          logger.debug("hash: " + hash)
          logger.debug("codice: " + lic)
          if lic.eql? hash
            ctrl.registra_licenza()
          else
            lbl_messaggio_errore.label = 'Codice errato!'
            txt_codice.activate()

            return
          end

          evt.skip()

        rescue Exception => e
          log_error(self, e)
        end
      end
      
    end
  end
end
