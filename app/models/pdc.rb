# encoding: utf-8

module Models
  class Pdc < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :pdc

    module Categoria
      CLIENTI = '220000'
      FORNITORI = '460000'
    end

    belongs_to :categoria_pdc, :foreign_key => 'categoria_pdc_id'
    belongs_to :banca, :foreign_key => 'banca_id'

    validates_presence_of :categoria_pdc,
      :message => "Inserire la categoria"

    validates_presence_of :codice,
      :message => "Inserire il codice"

    validates_presence_of :descrizione,
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice,
      :scope => :categoria_pdc_id,
      :message => "Codice pdc gia' utilizzato."

    def modificabile?
      return false if self.standard?
      num = 0
      unless self.id.nil?
        num += Models::TipoPagamento.count(:conditions => ["pdc_dare_id = ? or pdc_avere_id = ?", self.id, self.id])
        num += Models::Corrispettivo.count(:conditions => ["pdc_dare_id = ? or pdc_avere_id = ?", self.id, self.id])
        num += Models::Scrittura.count(:conditions => ["pdc_dare_id = ? or pdc_avere_id = ?", self.id, self.id])
        num += Models::RigaFatturaPdc.count(:conditions => ["pdc_id = ?", self.id])
        num += Models::Causale.count(:conditions => ["pdc_dare_id = ? or pdc_avere_id = ?", self.id, self.id])
        num += Models::Cliente.count(:conditions => ["pdc_id = ?", self.id])
        num += Models::Fornitore.count(:conditions => ["pdc_id = ?", self.id])
      end
      num == 0
    end

    def conto_economico?
      self.categoria_pdc.conto_economico?
    end

    # stato patrimoniale
    def conto_patrimoniale?
      self.categoria_pdc.conto_patrimoniale?
    end

    def costo?()
      self.categoria_pdc.costo?
    end

    def ricavo?()
      self.categoria_pdc.ricavo?
    end

    def attivo?()
      self.categoria_pdc.attivo?
    end

    def passivo?()
      self.categoria_pdc.passivo?
    end

    def cliente?
      self.categoria_pdc.clienti?
    end

    def fornitore?
      self.categoria_pdc.fornitori?
    end

  end
end