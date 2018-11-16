class AddCampiFatturaElettronica < ActiveRecord::Migration
  def self.up
    add_column :dati_azienda, :comune, :string, :limit => 50
    add_column :dati_azienda, :provincia, :string, :limit => 2
    add_column :dati_azienda, :regime_fiscale, :string, :limit => 50
  end

  def self.down
    remove_column :dati_azienda, :comune
    remove_column :dati_azienda, :provincia
    remove_column :dati_azienda, :regime_fiscale
  end
end
