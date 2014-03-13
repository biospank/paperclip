# encoding: utf-8

require 'app/models/base'

module Models
  class PagamentoPartitaDoppia < ActiveRecord::Base
    include Base::Model

    set_table_name :pagamenti_partita_doppia
    belongs_to :scrittura, :class_name => "Models::ScritturaPd", :foreign_key => 'partita_doppia_id'
    belongs_to :pagamento_fattura_cliente, :foreign_key => 'pagamento_fattura_cliente_id'
    belongs_to :pagamento_fattura_fornitore, :foreign_key => 'pagamento_fattura_fornitore_id'
    belongs_to :maxi_pagamento_cliente, :foreign_key => 'maxi_pagamento_cliente_id'
    belongs_to :maxi_pagamento_fornitore, :foreign_key => 'maxi_pagamento_fornitore_id'
  end
end