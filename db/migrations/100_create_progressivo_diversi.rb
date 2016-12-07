class CreateProgressivoDiversi < ActiveRecord::Migration
  def self.up
    create_table :progressivo_diversi do |t|
      t.integer :progressivo, :null => false
    end
    
    add_column :prima_nota, :diversi, :integer

  end

  def self.down
    drop_table :progressivo_diversi

    remove_column :prima_nota, :diversi
  end
end
