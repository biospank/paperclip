class AddScritturaParent < ActiveRecord::Migration
  def self.up
    add_column :prima_nota, :parent_id, :integer, :null => true

  end

  def self.down

  end
end
