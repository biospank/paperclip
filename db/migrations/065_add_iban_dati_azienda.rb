class AddIbanDatiAzienda < ActiveRecord::Migration
  def self.up
    add_column :dati_azienda, :iban, :string, :limit => 27

  end

  def self.down

  end
end
