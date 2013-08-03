class CreatePagamentiFattureFornitori < ActiveRecord::Migration
  def self.up
    create_table :pagamenti_fatture_fornitori do |t|
      t.integer :fattura_fornitore_id, :null => false
      t.integer :maxi_pagamento_fornitore_id
      t.decimal :importo, :null => false
      t.integer :range_temporale
      t.integer :tipo_pagamento_id
      t.integer :banca_id
      t.date    :data_pagamento, :null => false
      t.date    :data_registrazione, :null => false
      t.integer :registrato_in_prima_nota, :limit => 1, :default => 0
      t.string  :note, :limit => 100
    end

    execute "CREATE INDEX PAGAMENTI_FATTURE_FORNITORI_IDX ON PAGAMENTI_FATTURE_FORNITORI (id, fattura_fornitore_id, maxi_pagamento_fornitore_id, tipo_pagamento_id, banca_id, data_pagamento, data_registrazione)"

  end

  def self.down
    drop_table :pagamenti_fatture_fornitori
  end
end
