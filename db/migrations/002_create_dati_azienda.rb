class CreateDatiAzienda < ActiveRecord::Migration
  def self.up
    create_table :dati_azienda do |t|
      t.integer :azienda_id, :null => false
      t.string  :denominazione, :null => false, :limit => 100
      t.string  :p_iva, :limit => 11
      t.string  :cod_fisc, :null => false, :limit => 16
      t.string  :telefono, :limit => 50
      t.string  :fax, :limit => 50
      t.string  :e_mail, :limit => 100
      t.string  :indirizzo, :limit => 100
      t.string  :cap, :limit => 10
      t.string  :citta, :limit => 50

    end

    execute "INSERT INTO DATI_AZIENDA (azienda_id, denominazione, p_iva, cod_fisc, telefono) VALUES(1, 'Azienda Demo', '12345678910', '12345678910', '3252423775')"

  end

  def self.down
    drop_table :dati_azienda
  end
end
