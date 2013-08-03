class AddIvaDiff < ActiveRecord::Migration
  def self.up
    add_column :fatture_clienti, :iva_diff, :integer, :null => false, :limit => 1, :default => 0
    
  end

  def self.down

  end
end
