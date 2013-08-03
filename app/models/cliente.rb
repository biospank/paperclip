# encoding: utf-8

require 'app/models/base'

module Models
  class Cliente < ActiveRecord::Base
    include Base::Model

    set_table_name :clienti
    
    belongs_to :azienda
    
    has_many :ddt, :as => :cliente
    
    searchable_by :denominazione, :cod_fisc, :p_iva
    
    validates_presence_of :denominazione, 
      :message => "Inserire la denominazione"
    validates_presence_of :p_iva, 
      :unless => Proc.new { |cliente| cliente.no_p_iva? },
      :message => "Inserire la partita iva"
    validates_length_of :p_iva, 
      :is => 11, 
      :unless => Proc.new { |cliente| cliente.no_p_iva? },
      :message => "La partita iva deve essere di 11 caratteri"
    validates_presence_of :cod_fisc, 
      :if => Proc.new { |cliente| cliente.errors.empty? },
      :message => "Inserire il codice fiscale"
    validates_length_of :cod_fisc, 
      :is => 11, 
      :if => Proc.new { |cliente| cliente.cod_fisc and cliente.cod_fisc.match(/^[0-9]+$/) },
      :message => "Il codice fiscale deve essere di 11 caratteri"
    validates_length_of :cod_fisc, 
      :is => 16, 
      :if => Proc.new { |cliente| cliente.cod_fisc =~ /(\D)+/ },
      :message => "Il codice fiscale deve essere di 16 caratteri"

    validates_uniqueness_of :p_iva, 
      :if => Proc.new { |cliente| cliente.no_p_iva == 0 and cliente.errors.empty? },
      :scope => :azienda_id,
      :message => "La partita iva inserita e' gia' utilizzata"
    
    validates_uniqueness_of :cod_fisc, 
      :if => Proc.new { |cliente| cliente.errors.empty? },
      :scope => :azienda_id,
      :message => "Il codice fiscale inserito e' gia' utilizzato"
    
      
    def before_validation_on_create
      self.azienda = Azienda.current
      (self.cod_fisc ||= '').upcase!
    end

    def modificabile?
      num = 0
      num = Models::FatturaCliente.count(:conditions => ["cliente_id = ?", self.id])
      num += Models::Ddt.count(:conditions => ["cliente_id = ? and cliente_type = ?", self.id, 'Models::Cliente'])
      num += Models::IncassoRicorrente.count(:conditions => ["cliente_id = ?", self.id])
      num += Models::NotaSpese.count(:conditions => ["cliente_id = ?", self.id])
      num == 0
    end

    def build_conditions(query_str, parametri)
      unless new_record?
        query_str << "cliente_id = ?"
        parametri << self.id
      end
      
    end
    
    protected
    
    def validate()
      unless no_p_iva?
        if(Cliente.count(:conditions => ["cod_fisc = ? and azienda_id = ? and id <> ?", p_iva, Azienda.current.id, self]) > 0 or
              p_iva.eql?(Azienda.current.dati_azienda.p_iva) or p_iva.eql?(Azienda.current.dati_azienda.cod_fisc))
          errors.add(:p_iva, "La partita iva inserita e' gia' utilizzata")
        end
      end
      if(Cliente.count(:conditions => ["p_iva = ? and azienda_id = ? and id <> ?", cod_fisc, Azienda.current.id, self]) > 0 or
            cod_fisc.eql?(Azienda.current.dati_azienda.cod_fisc) or cod_fisc.eql?(Azienda.current.dati_azienda.p_iva))
        errors.add(:cod_fisc, "Il codice fiscale inserito e' gia' utilizzato")
      end
    end
    
  end
end
