# encoding: utf-8

require 'app/helpers/business_class_helper'

module Models
  class RigaFatturaCliente < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model
    
    set_table_name :righe_fatture_clienti
    belongs_to :fattura_cliente, :foreign_key => 'fattura_cliente_id'
    belongs_to :aliquota, :foreign_key => 'aliquota_id'
    has_one :scarico, :class_name => "Models::Scarico", :foreign_key => 'riga_fattura_id', :dependent => :nullify

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_presence_of :aliquota,
      :if => Proc.new { |riga| riga.errors.empty? },
      :message => "Inserire il codice aliquota, oppure premere F5 per la ricerca"
    
  end
end
