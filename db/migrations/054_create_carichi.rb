class CreateCarichi < ActiveRecord::Migration
  def self.up
    create_table :carichi do |t|
      t.integer :azienda_id, :null => false
      t.integer :riga_ordine_id # tiene traccia dei carichi effettuati da un ordine
      t.integer :qta, :null => false
      t.decimal :prezzo_unitario
      t.decimal :prezzo_vendita
      t.date    :data_carico, :null => false
      t.date    :data_esaurito
      t.string  :note, :limit => 300
      t.integer :lock_version, :null => false, :default => 0
    end

    execute "CREATE INDEX C_AZIENDA_FK_IDX ON carichi (azienda_id)"
    execute "CREATE INDEX C_RIGA_ORDINE_FK_IDX ON carichi (riga_ordine_id)"
    execute "CREATE INDEX C_DATA_CARICO_IDX ON carichi (data_carico)"

  end

  def self.down
    drop_table :carichi
  end
end
