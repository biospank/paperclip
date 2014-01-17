# encoding: utf-8

module Models
  class Pdc < ActiveRecord::Base
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
    
    set_table_name :pdc

    belongs_to :categoria_pdc, :foreign_key => 'categoria_pdc_id'

    validates_presence_of :categoria_pdc,
      :message => "Inserire la categoria"

    validates_presence_of :codice,
      :message => "Inserire il codice"

    validates_presence_of :descrizione,
      :message => "Inserire la descrizione"

    validates_presence_of :type,
      :message => "Inserire la tipologia"

    validates_uniqueness_of :codice,
      :scope => :categoria_pdc_id,
      :message => "Codice pdc gia' utilizzato."

    def label()
      self.class.name.split('::').last
    end

    def modificabile?
      num = 0
      unless self.id.nil?
        num += Models::Corrispettivo.count(:conditions => ["pdc_dare_id = ? or pdc_avere_id = ?", self.id, self.id])
        num += Models::RigaFatturaPdc.count(:conditions => ["pdc_id = ?", self.id])
        num += Models::Causale.count(:conditions => ["pdc_dare_id = ? or pdc_avere_id = ?", self.id, self.id])
        num += Models::Banca.count(:conditions => ["pdc_id = ?", self.id])
        num += Models::Cliente.count(:conditions => ["pdc_id = ?", self.id])
        num += Models::Fornitore.count(:conditions => ["pdc_id = ?", self.id])
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
      self.type == ATTIVO || self.type == COSTO
    end

    def ricavo?()
      self.type == PASSIVO || self.type == RICAVO
    end

    alias_method :attivo?, :costo?
    alias_method :passivo?, :ricavo?
  end
end