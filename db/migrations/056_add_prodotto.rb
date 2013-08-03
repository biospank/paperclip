class AddProdotto < ActiveRecord::Migration
  def self.up
    add_column :carichi, :prodotto_id, :integer

    execute "CREATE INDEX C_PRODOTTO_FK_IDX ON carichi (prodotto_id)"
  end

  def self.down

  end
end
