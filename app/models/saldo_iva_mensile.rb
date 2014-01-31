# encoding: utf-8

module Models
  class SaldoIvaMensile < ActiveRecord::Base
    include Base::Model

    set_table_name :saldi_iva_mensili

    belongs_to :azienda

  end
end