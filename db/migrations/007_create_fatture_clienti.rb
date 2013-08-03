class CreateFattureClienti < ActiveRecord::Migration
  def self.up
    create_table :fatture_clienti do |t|
      t.integer :azienda_id, :null => false
      t.integer :cliente_id, :null => false
      t.integer :ritenuta_id
      t.string  :num, :null => false, :limit => 20
      t.date    :data_emissione, :null => false
      t.decimal :imponibile, :null => false
      t.decimal :iva, :null => false
      t.decimal :importo, :null => false
      t.integer :nota_di_credito, :limit => 1, :null => false, :default => 0
      t.string  :destinatario, :limit => 100
      t.string  :indirizzo_dest, :limit => 100
      t.string  :cap_dest, :limit => 10
      t.string  :citta_dest, :limit => 50
      t.string  :rif_ddt, :limit => 50
      t.string  :rif_pagamento, :limit => 50
      t.integer :da_fatturazione, :limit => 1, :null => false, :default => 0
      t.integer :da_scadenzario, :limit => 1, :null => false, :default => 0
    end

    execute "CREATE INDEX FATTURE_CLIENTI_IDX ON FATTURE_CLIENTI (id, cliente_id, num, data_emissione, da_fatturazione, da_scadenzario)"

  end

  def self.down
    drop_table :fatture_clienti
  end
end
