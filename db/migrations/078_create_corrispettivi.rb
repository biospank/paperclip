class CreateCorrispettivi < ActiveRecord::Migration
  def self.up
    create_table :corrispettivi do |t|
      t.date    :data, :null => false
      t.decimal :importo, :null => false, :default => 0
      t.decimal :imponibile, :null => false, :default => 0
      t.decimal :iva, :null => false, :default => 0
      t.integer :registrato_in_prima_nota, :limit => 1, :default => 0
      t.integer :azienda_id, :null => false
      t.integer :aliquota_id, :null => false
      t.integer :pdc_dare_id
      t.integer :pdc_avere_id
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute "CREATE INDEX CORRISPETTIVI_DATA_IDX ON corrispettivi (data)"
    execute "CREATE INDEX CORRISPETTIVI_AZIENDA_FK_IDX ON corrispettivi (azienda_id)"
    execute "CREATE INDEX CORRISPETTIVI_ALIQUOTA_FK_IDX ON corrispettivi (aliquota_id)"
    execute "CREATE INDEX CORRISPETTIVI_PDC_DARE_FK_IDX ON corrispettivi (pdc_dare_id)"
    execute "CREATE INDEX CORRISPETTIVI_PDC_AVERE_FK_IDX ON corrispettivi (pdc_avere_id)"
  end

  def self.down
    drop_table :corrispettivi
  end
end
