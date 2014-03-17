# encoding: utf-8

require 'app/models/base'

module Models
  class DettaglioFatturaPartitaDoppia < ActiveRecord::Base
    include Base::Model

    set_table_name :dettaglio_fatture_partita_doppia
    belongs_to :scrittura, :class_name => "Models::ScritturaPd", :foreign_key => 'partita_doppia_id'
    belongs_to :dettaglio_fattura_cliente, :foreign_key => 'dettaglio_fattura_cliente_id'
    belongs_to :dettaglio_fattura_fornitore, :foreign_key => 'dettaglio_fattura_fornitore_id'
  end
end