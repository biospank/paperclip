class CreateCorrispettiviPartitaDoppia < ActiveRecord::Migration
  def self.up
    create_table :corrispettivi_partita_doppia do |t|
      t.integer :partita_doppia_id, :null => false
      t.integer :corrispettivo_id, :null => false
    end

    execute "CREATE INDEX CPD_PARTITA_DOPPIA_FK_IDX ON corrispettivi_partita_doppia (partita_doppia_id)"
    execute "CREATE INDEX CPD_CORRISPETTIVO_FK_IDX ON corrispettivi_partita_doppia (corrispettivo_id)"
  end

  def self.down
    drop_table :corrispettivi_partita_doppia
  end
end
