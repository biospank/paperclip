# encoding: utf-8

module Models
  class RigaFatturaPdc < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model

    set_table_name :righe_fattura_pdc
    belongs_to :fattura_cliente, :class_name => "Models::FatturaClienteScadenzario", :foreign_key => 'fattura_cliente_id'
    belongs_to :fattura_fornitore, :class_name => "Models::FatturaFornitore", :foreign_key => 'fattura_fornitore_id'
    belongs_to :pdc, :foreign_key => 'pdc_id'
    belongs_to :aliquota, :foreign_key => 'aliquota_id'
    belongs_to :norma, :foreign_key => 'norma_id'

    validates_presence_of :aliquota,
      :message => "Associare un codice aliquota."
    validates_presence_of :norma,
      :if => Proc.new { |riga_pdc| !riga_pdc.aliquota.nil? && riga_pdc.aliquota.percentuale.zero? },
      :message => "L'aliquota inserita è pari a zero: Inserire un codice norma."
    validates_presence_of :imponibile,
      :message => "Inserire l'imponibile."
    validates_presence_of :pdc,
      :if => Proc.new { |riga_pdc| configatron.bilancio.attivo },
      :message => "Associare un conto oppure premere F5 per la ricerca."

    # calcolo dell'imponibile partendo dal totale (importo)
    def calcola_imponibile(importo)
#      self.imponibile = (self.importo * 100 / (self.aliquota.percentuale + 100))
      self.imponibile = (importo - self.iva)
    end

    # scorporo iva partendo da un totale (importo)
    def calcola_iva(importo)
      self.iva = Helpers::ApplicationHelper.real((importo * self.aliquota.percentuale) / (self.aliquota.percentuale + 100))
      #self.iva = (self.imponibile * self.aliquota.percentuale / 100)
    end

    # calcolo detrazione partendo da un totale (importo)
    def calcola_detrazione()
      self.detrazione = Helpers::ApplicationHelper.real((self.iva * self.norma.percentuale) / 100)
    end

  end
end