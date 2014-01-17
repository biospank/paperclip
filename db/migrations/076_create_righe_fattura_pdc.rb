class CreateRigheFatturaPdc < ActiveRecord::Migration
  def self.up
    create_table :righe_fattura_pdc do |t|
      t.integer :fattura_cliente_id
      t.integer :fattura_fornitore_id
      t.integer :pdc_id, :null => false
      t.integer :aliquota_id, :null => false
      t.decimal :imponibile, :null => false
      t.decimal :iva, :null => false
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute "CREATE INDEX RFP_FATTURA_CLIENTE_FK_IDX ON righe_fattura_pdc (fattura_cliente_id)"
    execute "CREATE INDEX RFP_FATTURA_FORNITORE_FK_IDX ON righe_fattura_pdc (fattura_fornitore_id)"
    execute "CREATE INDEX RFP_PDC_FK_IDX ON righe_fattura_pdc (pdc_id)"
    execute "CREATE INDEX RFP_ALIQUOTA_FK_IDX ON righe_fattura_pdc (aliquota_id)"
  end

  def self.down
    drop_table :righe_fattura_pdc
  end
end
