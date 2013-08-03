class CreateRigheNotaSpese < ActiveRecord::Migration
  def self.up
    create_table :righe_nota_spese do |t|
      t.integer :nota_spese_id, :null => false
      t.integer :aliquota_id, :null => false
      t.integer :importo_iva, :limit => 1, :default => 0
      t.string  :descrizione, :null => false, :limit => 100
      t.integer :qta, :null => false
      t.decimal :importo, :null => false
    end

    execute "CREATE INDEX RIGHE_NOTA_SPESE_IDX ON RIGHE_NOTA_SPESE (id, nota_spese_id, aliquota_id)"

  end

  def self.down
    drop_table :righe_nota_spese
  end
end
