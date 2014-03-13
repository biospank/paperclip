class CreatePartitaDoppia < ActiveRecord::Migration
  def self.up
    create_table :partita_doppia do |t|
      t.integer :azienda_id, :null => false
      t.integer :causale_id
      t.integer :pdc_dare_id
      t.integer :pdc_avere_id
      t.integer :nc_pdc_dare_id
      t.integer :nc_pdc_avere_id
      t.text  :descrizione, :null => false, :limit => nil
      t.date    :data_operazione, :null => false
      t.datetime    :data_registrazione, :null => false
      t.integer :esterna, :limit => 1, :default => 0
      t.integer :congelata, :limit => 1, :default => 0
      t.decimal :importo
      t.string  :note, :limit => 300
      t.date :data_residuo, :null => true
      t.integer :parent_id, :null => true
    end

    execute "CREATE INDEX PD_AZIENDA_FK_IDX ON partita_doppia (azienda_id)"
    execute "CREATE INDEX PD_CAUSALE_FK_IDX ON partita_doppia (causale_id)"
    execute "CREATE INDEX PD_PDC_DARE_FK_IDX ON partita_doppia (pdc_dare_id)"
    execute "CREATE INDEX PD_PDC_AVERE_FK_IDX ON partita_doppia (pdc_avere_id)"
    execute "CREATE INDEX PD_NC_PDC_DARE_FK_IDX ON partita_doppia (nc_pdc_dare_id)"
    execute "CREATE INDEX PD_NC_PDC_AVERE_FK_IDX ON partita_doppia (nc_pdc_avere_id)"
    execute "CREATE INDEX PD_DATA_OPERAZIONE_IDX ON partita_doppia (data_operazione)"
    execute "CREATE INDEX PD_DATA_REGISTRAZIONE_IDX ON partita_doppia (data_registrazione)"
    execute "CREATE INDEX PD_PARENT_FK_IDX ON partita_doppia (parent_id)"

    add_column :pagamenti_fatture_clienti, :registrato_in_partita_doppia, :integer, :limit => 1, :default => 0
    add_column :pagamenti_fatture_fornitori, :registrato_in_partita_doppia, :integer, :limit => 1, :default => 0
    add_column :corrispettivi, :registrato_in_partita_doppia, :integer, :limit => 1, :default => 0
  end

  def self.down
    drop_table :partita_doppia
    remove_column :pagamenti_fatture_clienti, :registrato_in_partita_doppia
    remove_column :pagamenti_fatture_fornitori, :registrato_in_partita_doppia
    remove_column :corrispettivi, :registrato_in_partita_doppia
  end
end
