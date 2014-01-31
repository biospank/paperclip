class CreateCategoriePdc < ActiveRecord::Migration
  def self.up
    create_table :categorie_pdc do |t|
      t.string  :codice, :null => false, :limit => 10
      t.string  :descrizione, :limit => 100
      t.integer :attiva, :limit => 1, :null => false, :default => 1
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    add_column :pdc, :categoria_pdc_id, :integer
    add_column :dati_azienda, :liquidazione_iva, :integer, :limit => 1, :null => false, :default => 1

    execute "CREATE INDEX CATEGORIE_PDC_CODICE_IDX ON categorie_pdc (codice)"
    execute "CREATE INDEX PDC_CODICE_IDX ON pdc (codice)"
    execute "CREATE INDEX PDC_CATEGORIE_PDC_FK_IDX ON pdc (categoria_pdc_id)"

  end

  def self.down
    drop_table :categorie_pdc
    remove_column :pdc, :categoria_pdc_id
    remove_column :dati_azienda, :liquidazione_iva
    execute "DROP INDEX PDC_CODICE_IDX"
  end
end
