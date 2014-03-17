# encoding: utf-8

require 'app/models/base'

module Models
  class Fornitore < ActiveRecord::Base
    include Base::Model
    
    set_table_name :fornitori
    
    belongs_to :azienda
    belongs_to :pdc, :foreign_key => 'pdc_id'
    
    has_many :ddt, :as => :cliente

    searchable_by :denominazione, :cod_fisc, :p_iva
    
    validates_presence_of :denominazione, 
      :message => "Inserire la denominazione"
    validates_presence_of :p_iva, 
      :unless => Proc.new { |fornitore| fornitore.no_p_iva? },
      :message => "Inserire la partita iva"
    validates_length_of :p_iva, 
      :is => 11, 
      :unless => Proc.new { |fornitore| fornitore.no_p_iva? },
      :message => "La partita iva deve essere di 11 caratteri"
    validates_presence_of :cod_fisc, 
      :if => Proc.new { |fornitore| fornitore.errors.empty? },
      :message => "Inserire il codice fiscale"
    validates_length_of :cod_fisc, 
      :is => 11, 
      :if => Proc.new { |fornitore| fornitore.cod_fisc and fornitore.cod_fisc.match(/^[0-9]+$/) },
      :message => "Il codice fiscale deve essere di 11 caratteri"
    validates_length_of :cod_fisc, 
      :is => 16, 
      :if => Proc.new { |fornitore| fornitore.cod_fisc =~ /(\D)+/ },
      :message => "Il codice fiscale deve essere di 16 caratteri"

    validates_uniqueness_of :p_iva, 
      :if => Proc.new { |fornitore| fornitore.no_p_iva == 0 and fornitore.errors.empty? },
      :scope => :azienda_id,
      :message => "La partita iva inserita e' gia' utilizzata"
    
    validates_uniqueness_of :cod_fisc, 
      :if => Proc.new { |fornitore| fornitore.errors.empty? },
      :scope => :azienda_id,
      :message => "Il codice fiscale inserito e' gia' utilizzato"
    
    def before_validation_on_create
      self.azienda = Azienda.current
      (self.cod_fisc ||= '').upcase!
    end

    def before_create
      cat_pdc = Models::CategoriaPdc.find(:first, :conditions => ["codice = ?", 460])
      self.conto = Models::ProgressivoFornitore.next_sequence()
      Models::Pdc.create(
        :categoria_pdc => cat_pdc,
        :codice => self.conto,
        :descrizione => self.denominazione,
        :attivo => true,
        :standard => true,
        :hidden => true
      )
    end

    def modificabile?
      num = 0
      num = Models::FatturaFornitore.count(:conditions => ["fornitore_id = ?", self.id])
      num += Models::Ddt.count(:conditions => ["cliente_id = ? and cliente_type = ?", self.id, 'Models::Fornitore'])
      num == 0
    end

    def build_conditions(query_str, parametri)
      unless new_record?
        query_str << "fornitore_id = ?"
        parametri << self.id
      end
      
    end
    
    protected
    
    def validate()
      unless no_p_iva?
        if(Fornitore.count(:conditions => ["cod_fisc = ? and azienda_id = ? and id <> ?", p_iva, Azienda.current.id, self]) > 0 or
              p_iva.eql?(Azienda.current.dati_azienda.p_iva) or p_iva.eql?(Azienda.current.dati_azienda.cod_fisc))
          errors.add(:p_iva, "La partita iva inserita e' gia' utilizzata")
        end
      end
      if(Fornitore.count(:conditions => ["p_iva = ? and azienda_id = ? and id <> ?", cod_fisc, Azienda.current.id, self]) > 0 or
            cod_fisc.eql?(Azienda.current.dati_azienda.cod_fisc) or cod_fisc.eql?(Azienda.current.dati_azienda.p_iva))
        errors.add(:cod_fisc, "Il codice fiscale inserito e' gia' utilizzato")
      end
    end
    
  end
end
