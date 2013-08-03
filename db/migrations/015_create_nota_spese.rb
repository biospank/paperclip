class CreateNotaSpese < ActiveRecord::Migration
  def self.up
    create_table :nota_spese do |t|
      t.integer :azienda_id, :null => false
      t.integer :cliente_id, :null => false
      t.integer :fattura_cliente_id
      t.integer :ritenuta_id
      t.string  :num, :null => false, :limit => 20
      t.date    :data_emissione, :null => false
      t.decimal :importo, :null => false
    end

    execute "CREATE INDEX NOTA_SPESE_IDX ON NOTA_SPESE (id, num, data_emissione)"

  end

  def self.down
    drop_table :nota_spese
  end
end
