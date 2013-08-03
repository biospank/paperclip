class CreatePagamentiFattureClienti < ActiveRecord::Migration
  def self.up
    create_table :pagamenti_fatture_clienti do |t|
      t.integer :fattura_cliente_id, :null => false
      t.integer :maxi_pagamento_cliente_id
      t.decimal :importo, :null => false
      t.integer :range_temporale
      t.integer :tipo_pagamento_id
      t.integer :banca_id
      t.date    :data_pagamento, :null => false
      t.date    :data_registrazione, :null => false
      t.integer :registrato_in_prima_nota, :limit => 1, :default => 0
      t.string  :note, :limit => 100
    end

    execute "CREATE INDEX PAGAMENTI_FATTURE_CLIENTI_IDX ON PAGAMENTI_FATTURE_CLIENTI (id, fattura_cliente_id, maxi_pagamento_cliente_id, tipo_pagamento_id, banca_id, data_pagamento, data_registrazione)"

  end

  def self.down
    drop_table :pagamenti_fatture_clienti
  end
end
