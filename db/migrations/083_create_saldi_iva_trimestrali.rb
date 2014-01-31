class CreateSaldiIvaTrimestrali < ActiveRecord::Migration
  def self.up
    create_table :saldi_iva_trimestrali do |t|
      t.integer :azienda_id, :null => false
      t.integer :anno, :null => false
      t.integer :trimestre, :null => false
      t.decimal :debito
      t.decimal :credito
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute "CREATE INDEX SIT_AZIENDA_FK_IDX ON saldi_iva_trimestrali (azienda_id)"
    execute "CREATE INDEX SIT_ANNO_IDX ON saldi_iva_trimestrali (anno)"
    execute "CREATE INDEX SIT_TRIMESTRE_IDX ON saldi_iva_trimestrali (trimestre)"
  end

  def self.down
    drop_table :saldi_iva_trimestrali
  end
end
