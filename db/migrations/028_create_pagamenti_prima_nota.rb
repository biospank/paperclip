class CreatePagamentiPrimaNota < ActiveRecord::Migration
  def self.up
    create_table :pagamenti_prima_nota do |t|
      t.integer :prima_nota_id, :null => false
      t.integer :pagamento_fattura_cliente_id
      t.integer :pagamento_fattura_fornitore_id
      t.integer :maxi_pagamento_fattura_cliente_id
      t.integer :maxi_pagamento_fattura_fornitore_id
    end

    execute "CREATE INDEX PAGAMENTI_PRIMA_NOTA_IDX1 ON PAGAMENTI_PRIMA_NOTA (prima_nota_id)"
    execute "CREATE INDEX PAGAMENTI_PRIMA_NOTA_IDX2 ON PAGAMENTI_PRIMA_NOTA (pagamento_fattura_cliente_id)"
    execute "CREATE INDEX PAGAMENTI_PRIMA_NOTA_IDX3 ON PAGAMENTI_PRIMA_NOTA (pagamento_fattura_fornitore_id)"
  end

  def self.down
    drop_table :pagamenti_prima_nota
  end
end
