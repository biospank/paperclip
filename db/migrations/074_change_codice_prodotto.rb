class ChangeCodiceProdotto < ActiveRecord::Migration
  def self.up
    change_column :prodotti, :codice, :string, :limit => 20
  end

  def self.down

  end
end
