# encoding: utf-8

require 'app/models/base'

module Models
  class CorrispettivoPrimaNota < ActiveRecord::Base
    include Base::Model

    set_table_name :corrispettivi_prima_nota
    belongs_to :scrittura, :class_name => "Models::Scrittura", :foreign_key => 'prima_nota_id', :dependent => :destroy
    belongs_to :corrispettivo, :foreign_key => 'corrispettivo_id'
  end
end