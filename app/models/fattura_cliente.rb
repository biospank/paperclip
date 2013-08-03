# encoding: utf-8

require 'app/models/base'

module Models
  class FatturaCliente < ActiveRecord::Base
    include Base::Model

    set_table_name :fatture_clienti
    belongs_to :cliente, :foreign_key => 'cliente_id'
    belongs_to :azienda
    belongs_to :ritenuta, :foreign_key => 'ritenuta_id'
    has_many :nota_spese, :foreign_key => 'fattura_cliente_id'
  
    validates_presence_of :data_emissione, 
      :message => "Data inesistente o formalmente errata."

    validates_presence_of :num, 
      :message => "Inserire il numero di fattura o nota di credito."

    def ha_registrazioni_in_prima_nota?
      return PagamentoFatturaCliente.count(:conditions => ["fattura_cliente_id = ? and registrato_in_prima_nota = ?", self.id, 1]) > 0
    end
    
    def numero_duplicato?
      if self.nota_di_credito?
        self.class.search(:first, :conditions => ["num = ? and #{to_sql_year('data_emissione')} = ? and nota_di_credito = 1", num, data_emissione.year.to_s]) != nil
      else
        self.class.search(:first, :conditions => ["num = ? and #{to_sql_year('data_emissione')} = ? and nota_di_credito = 0", num, data_emissione.year.to_s]) != nil
      end
    end
    
  end

end
