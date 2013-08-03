class CreateMaxiPagamentiFornitori < ActiveRecord::Migration
  def self.up
    create_table :maxi_pagamenti_fornitori do |t|
      t.integer :azienda_id, :null => false
      t.decimal :importo, :null => false
      t.integer :range_temporale
      t.integer :tipo_pagamento_id
      t.integer :banca_id
      t.date    :data_pagamento, :null => false
      t.date    :data_registrazione, :null => false
      t.integer :chiuso, :limit => 1, :default => 0
      t.string  :note, :limit => 100
    end

    execute "CREATE INDEX MAXI_PAGAMENTI_FORNITORI_IDX ON MAXI_PAGAMENTI_FORNITORI (id, azienda_id, tipo_pagamento_id, banca_id, data_pagamento, data_registrazione)"

  end

  def self.down
    drop_table :maxi_pagamenti_fornitori
  end
end
