class CreateAliquote < ActiveRecord::Migration
  def self.up
    create_table :aliquote do |t|
      t.string  :codice, :null => false, :limit => 50
      t.decimal :percentuale, :null => false
      t.string  :descrizione, :null => false, :limit => 100
      t.integer :attiva, :limit => 1, :null => false, :default => 1
    end

  end

  def self.down
    drop_table :aliquote
  end
end
