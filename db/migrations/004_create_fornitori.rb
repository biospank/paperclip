class CreateFornitori < ActiveRecord::Migration
  def self.up
    create_table :fornitori do |t|
      t.integer :azienda_id, :null => false
      t.string  :denominazione, :null => false, :limit => 100
      t.integer :no_p_iva, :null => false, :limit => 1, :default => 0
      t.string  :p_iva, :limit => 11
      t.string  :cod_fisc, :null => false, :limit => 16
      t.string  :indirizzo, :limit => 100
      t.string  :comune, :limit => 50
      t.string  :provincia, :limit => 50
      t.string  :cap, :limit => 10
      t.string  :citta, :limit => 50
      t.string  :telefono, :limit => 50
      t.string  :cellulare, :limit => 50
      t.string  :fax, :limit => 50
      t.string  :e_mail, :limit => 100
      t.string  :note, :limit => 300
      t.integer :attivo, :null => false, :limit => 1, :default => 1        
      
    end

  end

  def self.down
    drop_table :fornitori
  end
end
