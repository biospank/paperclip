class CreateInteressiLiquidazioniTrimestrali < ActiveRecord::Migration
  def self.up
    create_table :interessi_liquidazioni_trimestrali do |t|
      t.integer :percentuale, :null => false
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute "insert into interessi_liquidazioni_trimestrali (id, percentuale) values (1, 1)"

  end

  def self.down
    drop_table :interessi_liquidazioni_trimestrali
  end
end
