class ChangePrezzoUnitario < ActiveRecord::Migration
  def self.up
    
    rename_column :righe_ordini, :prezzo_unitario, :prezzo_acquisto
    rename_column :prodotti, :prezzo_unitario, :prezzo_acquisto
    rename_column :carichi, :prezzo_unitario, :prezzo_acquisto
    remove_column :scarichi, :prezzo_unitario

  end

  def self.down

  end
end
