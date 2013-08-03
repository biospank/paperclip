class AddDatiAzienda < ActiveRecord::Migration
  def self.up
    add_column :dati_azienda, :cap_soc, :decimal, :null => true
    add_column :dati_azienda, :reg_imprese, :string, :null => true
    add_column :dati_azienda, :num_reg_imprese, :integer, :null => true
    add_column :dati_azienda, :num_rea, :string, :null => true
  end

  def self.down

  end
end
