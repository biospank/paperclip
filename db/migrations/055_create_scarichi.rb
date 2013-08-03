class CreateScarichi < ActiveRecord::Migration
  def self.up
    create_table :scarichi do |t|
      t.integer :azienda_id, :null => false
      t.integer :carico_id, :null => false
      t.integer :qta, :null => false
      t.decimal :prezzo_unitario
      t.decimal :prezzo_vendita
      t.date    :data_scarico, :null => false
      t.string  :note, :limit => 300
      t.integer :lock_version, :null => false, :default => 0
    end

    execute "CREATE INDEX S_AZIENDA_FK_IDX ON scarichi (azienda_id)"
    execute "CREATE INDEX S_CARICO_FK_IDX ON scarichi (carico_id)"
    execute "CREATE INDEX S_DATA_SCARICO_IDX ON scarichi (data_scarico)"

  end

  def self.down
    drop_table :scarichi
  end
end
