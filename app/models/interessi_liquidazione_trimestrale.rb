# encoding: utf-8

require 'app/models/base'

module Models
  class InteressiLiquidazioneTrimestrale < ActiveRecord::Base
    include Base::Model

    set_table_name :interessi_liquidazioni_trimestrali
    
    validates_presence_of :percentuale,
      :message => "Inserire la percentuale"

  end
end
