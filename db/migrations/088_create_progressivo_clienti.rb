class CreateProgressivoClienti < ActiveRecord::Migration
  def self.up
    create_table :progressivo_clienti do |t|
      t.integer :azienda_id, :null => false
      t.integer :progressivo, :null => false
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    Models::Azienda.all.each do |azienda|
      execute("insert into progressivo_clienti (azienda_id, progressivo) values (#{azienda.id}, 22000)")
    end

  end

  def self.down
    drop_table :progressivo_clienti
  end
end
