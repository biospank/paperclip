class CreateDettaglioFatturePartitaDoppia < ActiveRecord::Migration
  def self.up
    create_table :dettaglio_fatture_partita_doppia do |t|
      t.integer :partita_doppia_id, :null => false
      t.integer :fattura_cliente_id
      t.integer :fattura_fornitore_id
      t.integer :dettaglio_fattura_cliente_id
      t.integer :dettaglio_fattura_fornitore_id
    end

    execute "CREATE INDEX DFPD_PARTITA_DOPPIA_FK_IDX ON dettaglio_fatture_partita_doppia (partita_doppia_id)"
    execute "CREATE INDEX DFPD_FATTURA_CLIENTE_FK_IDX ON dettaglio_fatture_partita_doppia (fattura_cliente_id)"
    execute "CREATE INDEX DFPD_FATTURA_FORNITORE_FK_IDX ON dettaglio_fatture_partita_doppia (fattura_fornitore_id)"
    execute "CREATE INDEX DFPD_DETTAGLIO_FATTURA_CLIENTE_FK_IDX ON dettaglio_fatture_partita_doppia (dettaglio_fattura_cliente_id)"
    execute "CREATE INDEX DFPD_DETTAGLIO_FATTURA_FORNITORE_FK_IDX ON dettaglio_fatture_partita_doppia (dettaglio_fattura_fornitore_id)"
  end

  def self.down
    drop_table :dettaglio_fatture_partita_doppia
  end
end
