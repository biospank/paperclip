class CreateProdotti < ActiveRecord::Migration
  def self.up
    create_table :prodotti do |t|
      t.integer :azienda_id, :null => false
      t.string :codice, :null => false, :limit => 4
      t.string :bar_code, :limit => 50
      t.string :descrizione, :null => false, :limit => 100
      t.decimal :prezzo_unitario
      t.decimal :prezzo_vendita
      t.string  :note, :limit => 300
      t.integer :attivo, :limit => 1, :null => false, :default => 1
      t.integer :lock_version, :null => false, :default => 0
    end

    execute "CREATE INDEX P_AZIENDA_FK_IDX ON prodotti (azienda_id)"
    execute "CREATE INDEX P_CODICE_IDX ON prodotti (codice)"
    execute "CREATE INDEX P_BAR_CODE_IDX ON prodotti (bar_code)"

  end

  def self.down
    drop_table :prodotti
  end
end
