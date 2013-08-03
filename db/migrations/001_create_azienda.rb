class CreateAzienda < ActiveRecord::Migration
  def self.up
    create_table :azienda do |t|
      t.string :nome, :null => false, :limit => 100
      t.integer :attivita_merc, :default => 1, :limit => 1 # (puo assumere i valori [1 => commercio] [2 => servizi]
    end

    execute "INSERT INTO AZIENDA VALUES(1, 'Azienda Demo', 1)"
    
  end


  def self.down
    drop_table :azienda
  end
end
