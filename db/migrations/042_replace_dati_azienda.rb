class ReplaceDatiAzienda < ActiveRecord::Migration
  def self.up
    change_column :dati_azienda, :num_reg_imprese, :string, :null => true, :limit => 50
    change_column :dati_azienda, :reg_imprese, :string, :null => true, :limit => 100
    change_column :dati_azienda, :num_rea, :string, :null => true, :limit => 50
  end

  def self.down

  end
end
