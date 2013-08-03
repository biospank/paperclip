class AddBanca < ActiveRecord::Migration
  def self.up
    add_column :tipi_pagamento, :banca_id, :integer
  end

  def self.down

  end
end
