class CreateCorrispettiviPrimaNota < ActiveRecord::Migration
  def self.up
    create_table :corrispettivi_prima_nota do |t|
      t.integer :prima_nota_id, :null => false
      t.integer :corrispettivo_id, :null => false
    end

    execute "CREATE INDEX CORRISPETTIVI_PRIMA_NOTA_IDX1 ON CORRISPETTIVI_PRIMA_NOTA (prima_nota_id)"
    execute "CREATE INDEX CORRISPETTIVI_PRIMA_NOTA_IDX2 ON CORRISPETTIVI_PRIMA_NOTA (corrispettivo_id)"
  end

  def self.down
    drop_table :corrispettivi_prima_nota
  end
end
