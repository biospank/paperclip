# encoding: utf-8

require 'app/models/base'

module Models
  class PagamentoPrimaNota < ActiveRecord::Base
    include Base::Model

    set_table_name :pagamenti_prima_nota
    belongs_to :scrittura, :foreign_key => 'prima_nota_id', :dependent => :destroy
    belongs_to :pagamento_fattura_cliente, :foreign_key => 'pagamento_fattura_cliente_id'
    belongs_to :pagamento_fattura_fornitore, :foreign_key => 'pagamento_fattura_fornitore_id'
    belongs_to :maxi_pagamento_cliente, :foreign_key => 'maxi_pagamento_cliente_id'
    belongs_to :maxi_pagamento_fornitore, :foreign_key => 'maxi_pagamento_fornitore_id'
  end
end