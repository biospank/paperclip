class AddLockVersion < ActiveRecord::Migration
  def self.up
    add_column :clienti, :lock_version, :integer, :null => false, :default => 0
    add_column :fornitori, :lock_version, :integer, :null => false, :default => 0
    add_column :dati_azienda, :lock_version, :integer, :null => false, :default => 0
    add_column :ddt, :lock_version, :integer, :null => false, :default => 0
    add_column :righe_ddt, :lock_version, :integer, :null => false, :default => 0
    add_column :fatture_clienti, :lock_version, :integer, :null => false, :default => 0
    add_column :pagamenti_fatture_clienti, :lock_version, :integer, :null => false, :default => 0
    add_column :righe_fatture_clienti, :lock_version, :integer, :null => false, :default => 0
    add_column :fatture_fornitori, :lock_version, :integer, :null => false, :default => 0
    add_column :pagamenti_fatture_fornitori, :lock_version, :integer, :null => false, :default => 0
    add_column :nota_spese, :lock_version, :integer, :null => false, :default => 0
    add_column :righe_nota_spese, :lock_version, :integer, :null => false, :default => 0
    add_column :maxi_pagamenti_clienti, :lock_version, :integer, :null => false, :default => 0
    add_column :maxi_pagamenti_fornitori, :lock_version, :integer, :null => false, :default => 0
    add_column :aliquote, :lock_version, :integer, :null => false, :default => 0
    add_column :banche, :lock_version, :integer, :null => false, :default => 0
    add_column :causali, :lock_version, :integer, :null => false, :default => 0
    add_column :tipi_pagamento, :lock_version, :integer, :null => false, :default => 0
    add_column :incassi_ricorrenti, :lock_version, :integer, :null => false, :default => 0

  end

  def self.down

  end
end
