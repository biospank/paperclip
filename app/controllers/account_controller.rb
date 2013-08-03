# encoding: utf-8

module Controllers
  module AccountController
    include Controllers::BaseController
    
    def login(account = {})
      logger.debug("Utente: " + account[:user])
      logger.debug("Password: " + account[:password])
      logger.debug("Azienda: " + account[:azienda].to_s)
      if utente = Utente.authenticate(account[:user], account[:password], account[:azienda])
        Utente.current = utente
        Azienda.current = load_azienda(account[:azienda])
        return true
      else
        return false
      end
    end
    
  end
end