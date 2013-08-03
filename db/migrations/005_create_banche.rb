class CreateBanche < ActiveRecord::Migration
  def self.up
    create_table :banche do |t|
      t.integer :azienda_id, :null => false
      t.string  :descrizione, :null => false, :limit => 100
      t.string  :conto_corrente, :limit => 50
      t.string  :iban, :limit => 27
      t.string  :agenzia, :limit => 100
      t.string  :telefono, :limit => 50
      t.string  :indirizzo, :limit => 100
      t.integer :attiva, :limit => 1, :null => false, :default => 0
    end

  end

  def self.down
    drop_table :banche
  end
end
