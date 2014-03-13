# encoding: utf-8

require 'app/models/base'

module Models
  class CorrispettivoPartitaDoppia < ActiveRecord::Base
    include Base::Model

    set_table_name :corrispettivi_partita_doppia
    belongs_to :scrittura, :class_name => "Models::ScritturaPd", :foreign_key => 'partita_doppia_id'
    belongs_to :corrispettivo, :foreign_key => 'corrispettivo_id'
  end
end