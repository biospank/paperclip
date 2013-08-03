# encoding: utf-8

require 'app/helpers/business_class_helper'

module Models
  class RigaNotaSpese < ActiveRecord::Base
    include Helpers::BusinessClassHelper
    include Base::Model
    
    set_table_name :righe_nota_spese
    belongs_to :nota_spese, :foreign_key => 'nota_spese_id'
    belongs_to :aliquota, :foreign_key => 'aliquota_id'

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

    validates_presence_of :aliquota,
      :if => Proc.new { |riga| riga.errors.empty? },
      :message => "Inserire il codice aliquota, oppure premere F5 per la ricerca"
    
  end

end