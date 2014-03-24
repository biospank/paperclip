# encoding: utf-8

require 'app/models/base'

module Models
  class PrimaNotaPartitaDoppia < ActiveRecord::Base
    include Base::Model

    set_table_name :prima_nota_partita_doppia
    belongs_to :scrittura, :class_name => "Models::Scrittura", :foreign_key => 'prima_nota_id'
    belongs_to :scrittura_pd, :class_name => "Models::ScritturaPd", :foreign_key => 'partita_doppia_id', :dependent => :destroy
  end
end