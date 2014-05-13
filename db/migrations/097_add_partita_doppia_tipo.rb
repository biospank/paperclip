class AddPartitaDoppiaTipo < ActiveRecord::Migration
  def self.up
    add_column :partita_doppia, :tipo, :string
  end

  def self.down
    remove_column :partita_doppia, :tipo
  end
end