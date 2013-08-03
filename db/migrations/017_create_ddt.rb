class CreateDdt < ActiveRecord::Migration
  def self.up
    create_table :ddt do |t|
      t.integer :azienda_id, :null => false
      t.integer :cliente_id, :null => false
      t.string  :num, :null => false, :limit => 20
      t.date    :data_emissione, :null => false
      t.string  :mezzo_trasporto, :limit => 100
      t.string  :nome_cess, :limit => 100
      t.string  :indirizzo_cess, :limit => 100
      t.string  :cap_cess, :limit => 10
      t.string  :citta_cess, :limit => 50
      t.string  :nome_dest, :limit => 100
      t.string  :indirizzo_dest, :limit => 100
      t.string  :cap_dest, :limit => 10
      t.string  :citta_dest, :limit => 50
      t.string  :causale, :limit => 100
      t.string  :nome_vett, :limit => 100
      t.string  :indirizzo_vett, :limit => 100
      t.string  :cap_vett, :limit => 10
      t.string  :citta_vett, :limit => 50
      t.string  :mezzo_vett, :limit => 50
    end

    execute "CREATE INDEX DDT_IDX ON DDT (id, num, data_emissione)"

  end

  def self.down
    drop_table :ddt
  end
end
