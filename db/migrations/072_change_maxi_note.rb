class ChangeMaxiNote < ActiveRecord::Migration
  def self.up

    change_column :maxi_pagamenti_clienti, :note, :string, :limit => 150
    change_column :maxi_pagamenti_fornitori, :note, :string, :limit => 150

  end

  def self.down

  end
end
