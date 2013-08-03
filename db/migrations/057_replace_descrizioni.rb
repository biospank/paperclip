class ReplaceDescrizioni < ActiveRecord::Migration
  def self.up
    change_column :fatture_clienti, :citta_dest, :string, :limit => 100
    change_column :fatture_clienti, :rif_ddt, :string, :limit => 100
    change_column :fatture_clienti, :rif_pagamento, :string, :limit => 100
    change_column :righe_fatture_clienti, :descrizione, :string, :limit => 500
    change_column :righe_nota_spese, :descrizione, :string, :limit => 500
    change_column :righe_ddt, :descrizione, :string, :limit => 500
    change_column :ddt, :citta_cess, :string, :limit => 100
    change_column :ddt, :citta_dest, :string, :limit => 100
    change_column :ddt, :citta_vett, :string, :limit => 100
    change_column :ddt, :mezzo_vett, :string, :limit => 100
  end

  def self.down

  end
end
