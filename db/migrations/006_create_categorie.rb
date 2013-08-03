class CreateCategorie < ActiveRecord::Migration
  def self.up
    create_table :categorie do |t|
      t.string :descrizione, :null => false, :limit => 100
    end

    execute "INSERT INTO CATEGORIE VALUES (1, 'CLIENTI')"
    execute "INSERT INTO CATEGORIE VALUES (2, 'FORNITORI')"

  end

  def self.down
    drop_table :categorie
  end
end
