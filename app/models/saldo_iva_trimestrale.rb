# encoding: utf-8

module Models
  class SaldoIvaTrimestrale < ActiveRecord::Base
    include Base::Model

    set_table_name :saldi_iva_trimestrali

    belongs_to :azienda
    
  end
end