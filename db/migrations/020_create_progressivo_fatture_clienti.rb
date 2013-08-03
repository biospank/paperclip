class CreateProgressivoFattureClienti < ActiveRecord::Migration
  def self.up
    create_table :progressivo_fatture_clienti do |t|
      t.integer :azienda_id, :null => false
      t.integer :progressivo, :null => false
      t.integer :anno_rif, :null => false
    end

  end

  def self.down
    drop_table :progressivo_fatture_clienti
  end
end
