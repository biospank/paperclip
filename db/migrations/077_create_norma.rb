class CreateNorma < ActiveRecord::Migration
  def self.up
    create_table :norma do |t|
      t.string  :codice, :null => false, :limit => 50
      t.decimal :percentuale, :null => false
      t.string  :descrizione, :null => false, :limit => 100
      t.integer :attiva, :limit => 1, :null => false, :default => 1
    end

    add_column :righe_fattura_pdc, :norma_id, :integer
    add_column :righe_fattura_pdc, :detrazione, :decimal
    change_column :righe_fattura_pdc, :aliquota_id, :integer, :null => true
    add_column :prima_nota, :pdc_dare_id, :integer
    add_column :prima_nota, :pdc_avere_id, :integer
    remove_column :causali, :pdc_id
    add_column :causali, :pdc_dare_id, :integer
    add_column :causali, :pdc_avere_id, :integer

    execute "CREATE INDEX RFP_NORMA_FK_IDX ON righe_fattura_pdc (norma_id)"
    execute "CREATE INDEX PRIMA_NOTA_PDC_DARE_FK_IDX ON prima_nota (pdc_dare_id)"
    execute "CREATE INDEX PRIMA_NOTA_PDC_AVERE_FK_IDX ON prima_nota (pdc_avere_id)"
    execute "CREATE INDEX CAUSALI_PDC_DARE_FK_IDX ON causali (pdc_dare_id)"
    execute "CREATE INDEX CAUSALI_PDC_AVERE_FK_IDX ON causali (pdc_avere_id)"
  end

  def self.down
    drop_table :norma
    remove_column :righe_fattura_pdc, :norma_id
    remove_column :righe_fattura_pdc, :detrazione
    remove_column :prima_nota, :pdc_dare_id
    remove_column :prima_nota, :pdc_avere_id
    remove_column :causali, :pdc_dare_id
    remove_column :causali, :pdc_avere_id
    add_column :causali, :pdc_id, :integer
  end
end
