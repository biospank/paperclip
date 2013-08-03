class CreateMovimenti < ActiveRecord::Migration
  def self.up
    create_table :movimenti do |t|
      t.string  :type
      t.integer :prodotto_id, :null => false
      t.integer :riga_ordine_id # tiene traccia dei carichi effettuati da un ordine
      t.integer :riga_fattura_id # tiene traccia degli scarichi che generano righe di una fattura
      t.integer :qta, :null => false
      t.decimal :prezzo_acquisto
      t.decimal :prezzo_vendita
      t.date    :data, :null => false
      t.string  :note, :limit => 300
      t.integer :lock_version, :null => false, :default => 0
      t.timestamps
    end

    execute "CREATE INDEX M_PRODOTTO_FK_IDX ON movimenti (prodotto_id)"
    execute "CREATE INDEX M_RIGA_ORDINE_FK_IDX ON movimenti (riga_ordine_id)"
    execute "CREATE INDEX M_RIGA_FATTURA_FK_IDX ON movimenti (riga_fattura_id)"
    execute "CREATE INDEX M_DATA_IDX ON movimenti (data)"

    move_carichi_sql =<<-eo_move_carichi_sql
      INSERT INTO movimenti
        (type, prodotto_id, qta, prezzo_acquisto, prezzo_vendita, data, note, created_at, updated_at)
      SELECT 'Carico', prodotto_id, qta, prezzo_acquisto, prezzo_vendita, data_carico, note, created_at, updated_at
        FROM carichi
    eo_move_carichi_sql

    execute move_carichi_sql

    move_scarichi_sql =<<-eo_move_scarichi_sql
      INSERT INTO movimenti
        (type, prodotto_id, qta, prezzo_vendita, data, note, created_at, updated_at)
      SELECT 'Scarico', prodotto_id, qta, prezzo_vendita, data_scarico, note, created_at, updated_at
        FROM scarichi
    eo_move_scarichi_sql

    execute move_scarichi_sql

    execute "delete from movimenti where id in (select m.id from movimenti m left join prodotti p on m.prodotto_id = p.id where p.id is null)"
    
    execute "DROP TABLE carichi"
    execute "DROP TABLE scarichi"
  end

  def self.down
    drop_table :movimenti
  end
end
