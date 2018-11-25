class AddCampiFatturaElettronica < ActiveRecord::Migration
  def self.up
    add_column :dati_azienda, :comune, :string, :limit => 50
    add_column :dati_azienda, :provincia, :string, :limit => 2
    add_column :dati_azienda, :regime_fiscale, :string, :limit => 50
    add_column :dati_azienda, :codice_identificativo, :string, :limit => 50, :default => '0000000'
    add_column :fatture_clienti, :tipo_documento, :string, :limit => 50
    add_column :fatture_clienti, :tipo_ritenuta, :string, :limit => 50
    add_column :fatture_clienti, :causale_pagamento, :string, :limit => 50
  end

  def self.down
    remove_column :dati_azienda, :comune
    remove_column :dati_azienda, :provincia
    remove_column :dati_azienda, :regime_fiscale
    remove_column :dati_azienda, :codice_identificativo
    remove_column :fatture_clienti, :tipo_documento
    remove_column :fatture_clienti, :tipo_ritenuta
    remove_column :fatture_clienti, :causale_pagamento
  end
end
