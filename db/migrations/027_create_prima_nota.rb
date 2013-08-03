class CreatePrimaNota < ActiveRecord::Migration
  def self.up
    create_table :prima_nota do |t|
      t.integer :azienda_id, :null => false
      t.integer :causale_id
      t.integer :banca_id
      t.string  :descrizione, :null => false, :limit => 500
      t.date    :data_operazione, :null => false
      t.datetime    :data_registrazione, :null => false
      t.integer :esterna, :limit => 1, :default => 0
      t.integer :congelata, :limit => 1, :default => 0
      t.decimal :cassa_dare
      t.decimal :cassa_avere
      t.decimal :banca_dare
      t.decimal :banca_avere
      t.decimal :fuori_partita_dare
      t.decimal :fuori_partita_avere
      t.string  :note, :limit => 300
    end

    execute "CREATE INDEX PRIMA_NOTA_IDX ON PRIMA_NOTA (id, azienda_id, causale_id, banca_id, data_operazione, data_registrazione)"

  end

  def self.down
    drop_table :prima_nota
  end
end
