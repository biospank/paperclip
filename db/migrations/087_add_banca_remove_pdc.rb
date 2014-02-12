class AddBancaRemovePdc < ActiveRecord::Migration
  def self.up
    add_column :pdc, :banca_id, :integer
    remove_column :banche, :pdc_id

  end

  def self.down
    remove_column :pdc, :banca_id
    add_column :banche, :pdc_id, :integer
  end
end
