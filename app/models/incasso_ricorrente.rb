# encoding: utf-8

module Models
  class IncassoRicorrente < ActiveRecord::Base
    include Base::Model
    
    set_table_name :incassi_ricorrenti
    belongs_to :cliente

    validates_presence_of :importo, 
      :message => "Inserire l'importo"

    validates_presence_of :descrizione, 
      :message => "Inserire la descrizione"

  end
end