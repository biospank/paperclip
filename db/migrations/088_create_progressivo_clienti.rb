class CreateProgressivoClienti < ActiveRecord::Migration
  def self.up
    create_table :progressivo_clienti do |t|
      t.integer :progressivo, :null => false
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute("insert into progressivo_clienti (progressivo) values (22000)")

  end

  def self.down
    drop_table :progressivo_clienti
  end
end
