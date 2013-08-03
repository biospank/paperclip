class RemoveAziendaCaricoScarico < ActiveRecord::Migration
  def self.up
    remove_column :carichi, :azienda_id
    remove_column :scarichi, :azienda_id
  end

  def self.down
    add_column :carichi, :azienda_id, :integer
    add_column :scarichi, :azienda_id, :integer

  end
end
