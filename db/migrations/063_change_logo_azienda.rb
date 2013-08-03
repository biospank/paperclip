class ChangeLogoAzienda < ActiveRecord::Migration
  def self.up
    remove_column :dati_azienda, :logo
    add_column :dati_azienda, :logo, :binary, :default => nil
    add_column :dati_azienda, :logo_tipo, :string, :limit => 5, :default => nil
  end

  def self.down
    remove_column :dati_azienda, :logo_tipo
  end
end
