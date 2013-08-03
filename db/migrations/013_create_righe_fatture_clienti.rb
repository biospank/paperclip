class CreateRigheFattureClienti < ActiveRecord::Migration
  def self.up
    create_table :righe_fatture_clienti do |t|
      t.integer :fattura_cliente_id, :null => false
      t.integer :aliquota_id, :null => false
      t.integer :importo_iva, :limit => 1, :default => 0
      t.string  :descrizione, :null => false, :limit => 100
      t.integer :qta, :null => false
      t.decimal :importo, :null => false
    end

    execute "CREATE INDEX RIGHE_FATTURE_CLIENTI_IDX ON RIGHE_FATTURE_CLIENTI (id, fattura_cliente_id, aliquota_id)"

  end

  def self.down
    drop_table :righe_fatture_clienti
  end
end
