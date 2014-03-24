class CreatePrimaNotaPartitaDoppia < ActiveRecord::Migration
  def self.up
    create_table :prima_nota_partita_doppia do |t|
      t.integer :prima_nota_id, :null => false
      t.integer :partita_doppia_id, :null => false
    end

    execute "CREATE INDEX PNPD_PRIMA_NOTA_FK_IDX ON prima_nota_partita_doppia (prima_nota_id)"
    execute "CREATE INDEX PNPD_PARTITA_DOPPIA_FK_IDX ON prima_nota_partita_doppia (partita_doppia_id)"
  end

  def self.down
    drop_table :prima_nota_partita_doppia
  end
end
