class CreateProgressivoFornitori < ActiveRecord::Migration
  def self.up
    create_table :progressivo_fornitori do |t|
      t.integer :progressivo, :null => false
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute("insert into progressivo_fornitori (progressivo) values (46000)")

  end

  def self.down
    drop_table :progressivo_fornitori
  end
end
