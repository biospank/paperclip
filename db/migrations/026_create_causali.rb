class CreateCausali < ActiveRecord::Migration
  def self.up
    create_table :causali do |t|
      t.string  :descrizione, :limit => 100
      t.string  :descrizione_agg, :limit => 200
      t.integer :banca_id
      t.integer :cassa_dare, :limit => 1, :default => 0
      t.integer :cassa_avere, :limit => 1, :default => 0
      t.integer :banca_dare, :limit => 1, :default => 0
      t.integer :banca_avere, :limit => 1, :default => 0
      t.integer :fuori_partita_dare, :limit => 1, :default => 0
      t.integer :fuori_partita_avere, :limit => 1, :default => 0
      t.integer :attiva, :limit => 1, :null => false, :default => 1
    end

  end

  def self.down
    drop_table :causali
  end
end
