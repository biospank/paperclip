class CreatePagamentiPartitaDoppia < ActiveRecord::Migration
  def self.up
    create_table :pagamenti_partita_doppia do |t|
      t.integer :partita_doppia_id, :null => false
      t.integer :pagamento_fattura_cliente_id
      t.integer :pagamento_fattura_fornitore_id
      t.integer :maxi_pagamento_cliente_id
      t.integer :maxi_pagamento_fornitore_id
    end

    execute "CREATE INDEX PPD_PARTITA_DOPPIA_FK_IDX ON pagamenti_partita_doppia (partita_doppia_id)"
    execute "CREATE INDEX PPD_PAGAMENTO_FATTURA_CLIENTE_FK_IDX ON pagamenti_partita_doppia (pagamento_fattura_cliente_id)"
    execute "CREATE INDEX PPD_PAGAMENTO_FATTURA_FORNITORE_FK_IDX ON pagamenti_partita_doppia (pagamento_fattura_fornitore_id)"
    execute "CREATE INDEX PPD_MAXI_PAGAMENTO_CLIENTE_FK_IDX ON pagamenti_partita_doppia (maxi_pagamento_cliente_id)"
    execute "CREATE INDEX PPD_MAXI_PAGAMENTO_FORNITORE_FK_IDX ON pagamenti_partita_doppia (maxi_pagamento_fornitore_id)"
  end

  def self.down
    drop_table :pagamenti_partita_doppia
  end
end
