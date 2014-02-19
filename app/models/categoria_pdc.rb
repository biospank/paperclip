# encoding: utf-8

module Models
  class CategoriaPdc < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    # conto economico
    COSTO = 'Costo'
    RICAVO = 'Ricavo'
    # stato patrimoniale
    ATTIVO = 'Attivo'
    PASSIVO = 'Passivo'

# tabella riassuntiva
#
#   | DARE    | AVERE   |
#    -------------------
#   | ATTIVO  | PASSIVO | (STATO PATRIMONIALE)
#    -------------------
#   | COSTI   | RICAVI  | (CONTO ECONOMICO)
#    -------------------
#

    set_table_name :categorie_pdc

    validates_presence_of :codice,
      :message => "Inserire il codice"

    validates_presence_of :descrizione,
      :message => "Inserire la descrizione"

    validates_presence_of :type,
      :message => "Inserire la tipologia"

    validates_uniqueness_of :codice,
      :message => "Codice catagoria gia' utilizzato."

    def label()
      self.class.name.split('::').last
    end

    def modificabile?
      return false if self.standard?
      num = 0
      unless self.id.nil?
        num += Models::Pdc.count(:conditions => ["categoria_pdc_id = ?", self.id])
      end
      num == 0
    end

    def conto_economico?
      self.type == COSTO || self.type == RICAVO
    end

    # stato patrimoniale
    def conto_patrimoniale?
      self.type == ATTIVO || self.type == PASSIVO
    end

    def costo?()
      self.type == COSTO
    end

    def ricavo?()
      self.type == RICAVO
    end

    def attivo?()
      self.type == ATTIVO
    end

    def passivo?()
      self.type == PASSIVO
    end

  end
end