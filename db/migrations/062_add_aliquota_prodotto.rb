class AddAliquotaProdotto < ActiveRecord::Migration
  def self.up
    add_column :prodotti, :aliquota_id, :integer

    execute "CREATE INDEX P_ALIQUOTA_FK_IDX ON prodotti (aliquota_id)"
  end

  def self.down
    remove_column :prodotti, :aliquota_id
  end
end
