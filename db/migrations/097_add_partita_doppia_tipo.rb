class AddPartitaDoppiaTipo < ActiveRecord::Migration
  def self.up
    add_column :partita_doppia, :tipo, :string, :limit => 50
  end

  def self.down
    remove_column :partita_doppia, :tipo
  end
end