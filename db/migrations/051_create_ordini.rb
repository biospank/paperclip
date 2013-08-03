class CreateOrdini < ActiveRecord::Migration
  def self.up
    create_table :ordini do |t|
      t.integer :azienda_id, :null => false
      t.integer :fornitore_id, :null => false
      t.string  :num, :null => false, :limit => 20
      t.date    :data_emissione, :null => false
      t.integer :stato, :default => 1 # può assumere i valori (1=Aperto, 2=Inviato, 3=Chiuso)
      t.date    :data_chiusura
      t.string  :note, :limit => 300
      t.integer :lock_version, :null => false, :default => 0
  end

    execute "CREATE INDEX O_AZIENDA_FK_IDX ON ordini (azienda_id)"
    execute "CREATE INDEX O_FORNITORE_FK_IDX ON ordini (fornitore_id)"
    execute "CREATE INDEX O_DATA_EMISSIONE_IDX ON ordini (data_emissione)"
    execute "CREATE INDEX O_STATO_IDX ON ordini (stato)"

  end

  def self.down
    drop_table :ordini
  end
end
