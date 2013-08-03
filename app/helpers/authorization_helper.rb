module Helpers
  module AuthorizationHelper

    def can?(azione, modulo)
      return true if Models::Utente.system?
#      logger.debug("modulo: #{modulo}")
#      logger.debug("moduli: #{Models::Azienda.current.moduli.map(&:modulo_id)}")
#      logger.debug("azienda include modulo: #{Models::Azienda.current.include?(modulo)}")
      return true if Models::Utente.admin? && Models::Azienda.current.include?(modulo)
      can = false
      if permesso = Models::Utente.current.permessi_by(modulo)
        if permesso.modulo_azienda.attivo?
          case azione
          when :read
            can = permesso.lettura?
          when :write
            can = permesso.scrittura?
          end
        end
      end
      return can
    end

    def cannot?(azione, modulo)
      can?(azione, modulo) ? false : true
    end

  end
end
