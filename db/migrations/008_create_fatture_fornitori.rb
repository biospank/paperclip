class CreateFattureFornitori < ActiveRecord::Migration
  def self.up
    create_table :fatture_fornitori do |t|
      t.integer :azienda_id, :null => false
      t.integer :fornitore_id, :null => false
      t.string  :num, :null => false, :limit => 20
      t.date    :data_emissione, :null => false
      t.decimal :importo, :null => false
      t.integer :nota_di_credito, :limit => 1, :null => false, :default => 0
    end

    execute "CREATE INDEX FATTURE_FORNITORI_IDX ON FATTURE_FORNITORI (id, fornitore_id, num, data_emissione)"

  end

  def self.down
    drop_table :fatture_fornitori
  end
end
