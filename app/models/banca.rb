# encoding: utf-8

require 'app/models/base'

module Models
  class Banca < ActiveRecord::Base
    include Base::Model

    set_table_name :banche
    
    belongs_to :azienda
    belongs_to :pdc, :foreign_key => 'pdc_id'

    named_scope :attive, :conditions => {:attiva => 1}
    named_scope :default, :conditions => {:predefinita => 1}

    before_save do |banca| 
      Banca.update_all('predefinita = 0') if banca.predefinita? 
    end
    
    validates_presence_of :codice, 
      :message => "Inserire il codice"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_uniqueness_of :codice, 
      :scope => :azienda_id,
      :message => "Codice banca gia' utilizzato."

    validates_presence_of :pdc,
      :if => Proc.new { |banca| configatron.bilancio.attivo },
      :message => "Associare un codice pdc oppure premere F5 per la ricerca."

    def before_validation_on_create()
      self.azienda = Azienda.current
    end
    
    def modificabile?
      num = 0
      unless self.new_record?
        num = Models::TipoPagamento.count(:conditions => ["banca_id = ?", self.id])
        num += Models::PagamentoFatturaCliente.count(:conditions => ["banca_id = ?", self.id])
        num += Models::PagamentoFatturaFornitore.count(:conditions => ["banca_id = ?", self.id]) if num.zero?
        num += Models::MaxiPagamentoCliente.count(:conditions => ["banca_id = ?", self.id]) if num.zero?
        num += Models::MaxiPagamentoFornitore.count(:conditions => ["banca_id = ?", self.id]) if num.zero?
        num += Models::Scrittura.count(:conditions => ["banca_id = ?", self.id]) if num.zero?
        num += Models::Causale.count(:conditions => ["banca_id = ?", self.id]) if num.zero?
      end
    
      num == 0
    end
    
  end
end
