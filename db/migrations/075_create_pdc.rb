class CreatePdc < ActiveRecord::Migration
  def self.up
    create_table :pdc do |t|
      t.string  :type
      t.string  :codice, :null => false, :limit => 50
      t.string  :descrizione, :limit => 100
      t.integer :attivo, :limit => 1, :null => false, :default => 1
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    add_column :clienti, :pdc_id, :integer
    add_column :fornitori, :pdc_id, :integer
    add_column :causali, :pdc_id, :integer
    add_column :banche, :pdc_id, :integer

    execute "CREATE INDEX CLIENTI_PDC_FK_IDX ON clienti (pdc_id)"
    execute "CREATE INDEX FORNITORI_PDC_FK_IDX ON fornitori (pdc_id)"
    execute "CREATE INDEX CAUSALI_PDC_FK_IDX ON causali (pdc_id)"
    execute "CREATE INDEX BANCHE_PDC_FK_IDX ON banche (pdc_id)"
  end

  def self.down
    drop_table :pdc
    remove_column :clienti, :pdc_id
    remove_column :fornitori, :pdc_id
    remove_column :causali, :pdc_id
    remove_column :banche, :pdc_id
  end
end
