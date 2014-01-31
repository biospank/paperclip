class CreateSaldiIvaMensili < ActiveRecord::Migration
  def self.up
    create_table :saldi_iva_mensili do |t|
      t.integer :azienda_id, :null => false
      t.integer :anno, :null => false
      t.integer :mese, :null => false
      t.decimal :debito
      t.decimal :credito
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute "CREATE INDEX SIM_AZIENDA_FK_IDX ON saldi_iva_mensili (azienda_id)"
    execute "CREATE INDEX SIM_ANNO_IDX ON saldi_iva_mensili (anno)"
    execute "CREATE INDEX SIM_MESE_IDX ON saldi_iva_mensili (mese)"
  end

  def self.down
    drop_table :saldi_iva_mensili
  end
end
