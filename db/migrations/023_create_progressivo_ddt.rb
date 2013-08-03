class CreateProgressivoDdt < ActiveRecord::Migration
  def self.up
    create_table :progressivo_ddt do |t|
      t.integer :azienda_id, :null => false
      t.integer :progressivo, :null => false
      t.integer :anno_rif, :null => false
    end

  end

  def self.down
    drop_table :progressivo_ddt
  end
end
