class CreateIncassiRicorrenti < ActiveRecord::Migration
  def self.up
    create_table :incassi_ricorrenti do |t|
      t.integer :cliente_id, :null => false
      t.decimal :importo, :null => false
      t.string  :descrizione, :limit => 100
      t.integer :attivo, :limit => 1, :null => false, :default => 0
    end

    execute "CREATE INDEX INCASSI_RICORRENTI_IDX ON INCASSI_RICORRENTI (id, cliente_id, descrizione)"

  end

  def self.down
    drop_table :incassi_ricorrenti
  end
end
