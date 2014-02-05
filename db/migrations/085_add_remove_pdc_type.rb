class AddRemovePdcType < ActiveRecord::Migration
  def self.up
    add_column :categorie_pdc, :type, :string
    remove_column :pdc, :type

  end

  def self.down
    remove_column :categorie_pdc, :type
    add_column :pdc, :type, :string
  end
end
