class CreateMagazzini < ActiveRecord::Migration
  def self.up
    create_table :magazzini do |t|
      t.integer :azienda_id, :null => false
      t.string  :nome, :null => false, :limit => 50
      t.string  :descrizione
      t.integer :attivo, :null => false, :limit => 1, :default => 1
      t.integer :predefinito, :null => false, :limit => 1, :default => 0
      t.integer :lock_version, :null => false, :default => 0
    end

    execute "CREATE INDEX M_AZIENDA_FK_IDX ON magazzini (azienda_id)"

    Models::Azienda.all.each do |az|
      execute "insert into magazzini (id, azienda_id, nome, descrizione, attivo, predefinito) values (null, #{az.id}, 'Default', '', 1, 1)"
    end

    add_column :movimenti, :magazzino_id, :integer, :null => false, :default => 1

    Models::Azienda.all.each do |az|
      prod_ids = Models::Prodotto.find(:all, :conditions => ["azienda_id = ?", az.id]).map(&:id)
      Models::Movimento.update_all("magazzino_id = #{az.magazzini.first.id}", ["prodotto_id in(?)", prod_ids.join(',')])
    end

    execute "CREATE INDEX M_MAGAZZINO_FK_IDX ON movimenti (magazzino_id)"

  end

  def self.down
    drop_table :magazzini
    remove_column :movimenti, :magazzino_id
  end
end
