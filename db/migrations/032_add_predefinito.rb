class AddPredefinito < ActiveRecord::Migration
  def self.up
    add_column :aliquote, :predefinita, :integer, :null => false, :limit => 1, :default => 0
    add_column :ritenute, :predefinita, :integer, :null => false, :limit => 1, :default => 0
    add_column :banche, :predefinita, :integer, :null => false, :limit => 1, :default => 0 # la banca e' sempre subordinata al tipo pagamento o alla causale
    add_column :causali, :predefinita, :integer, :null => false, :limit => 1, :default => 0
    add_column :tipi_pagamento, :predefinito, :integer, :null => false, :limit => 1, :default => 0
  end

  def self.down

  end
end
