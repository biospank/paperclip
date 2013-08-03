class CreateRigheOrdini < ActiveRecord::Migration
  def self.up
    create_table :righe_ordini do |t|
      t.integer :ordine_id, :null => false
      t.integer :prodotto_id, :null => false
      t.integer :qta, :null => false
      t.decimal :prezzo_unitario
      t.decimal :prezzo_vendita
      t.integer :lock_version, :null => false, :default => 0
    end

    execute "CREATE INDEX RO_ORDINE_FK_IDX ON righe_ordini (ordine_id)"
    execute "CREATE INDEX RO_PRODOTTO_FK_IDX ON righe_ordini (prodotto_id)"

  end

  def self.down
    drop_table :righe_ordini
  end
end
