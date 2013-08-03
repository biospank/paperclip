class CreateTipiPagamento < ActiveRecord::Migration
  def self.up
    create_table :tipi_pagamento do |t|
      t.integer :categoria_id, :null => false
      t.string  :descrizione, :null => false, :limit => 50
      t.string  :descrizione_agg, :limit => 50
      t.integer :cassa_dare, :limit => 1, :default => 0
      t.integer :cassa_avere, :limit => 1, :default => 0
      t.integer :banca_dare, :limit => 1, :default => 0
      t.integer :banca_avere, :limit => 1, :default => 0
      t.integer :fuori_partita_dare, :limit => 1, :default => 0
      t.integer :fuori_partita_avere, :limit => 1, :default => 0
      t.integer :nc_cassa_dare, :limit => 1, :default => 0
      t.integer :nc_cassa_avere, :limit => 1, :default => 0
      t.integer :nc_banca_dare, :limit => 1, :default => 0
      t.integer :nc_banca_avere, :limit => 1, :default => 0
      t.integer :nc_fuori_partita_dare, :limit => 1, :default => 0
      t.integer :nc_fuori_partita_avere, :limit => 1, :default => 0
      t.integer :attivo, :null => false, :limit => 1, :default => 1
    end

    execute "INSERT INTO TIPI_PAGAMENTO VALUES (1, 1, 'CONTANTI', '', 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (2, 1, 'ASSEGNO', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (3, 1, 'BONIFICO', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (4, 1, 'CAMBIALI', '', 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (5, 1, 'RI.BA.', '', 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (6, 1, 'IN ATTESA', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (7, 2, 'CONTANTI', '', 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (8, 2, 'ASSEGNO', '', 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (9, 2, 'BONIFICO', '', 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (10, 2, 'CAMBIALI', '', 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (11, 2, 'RI.BA.', '', 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1)"
    execute "INSERT INTO TIPI_PAGAMENTO VALUES (12, 2, 'IN ATTESA', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)"

  end

  def self.down
    drop_table :tipi_pagamento
  end
end
