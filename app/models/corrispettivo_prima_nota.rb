# encoding: utf-8

require 'app/models/base'

module Models
  class CorrispettivoPrimaNota < ActiveRecord::Base
    include Base::Model

    set_table_name :corrispettivi_prima_nota
    belongs_to :scrittura, :foreign_key => 'prima_nota_id'
    belongs_to :corrispettivo, :foreign_key => 'corrispettivo_id'
  end
end