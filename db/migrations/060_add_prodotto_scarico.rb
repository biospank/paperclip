class AddProdottoScarico < ActiveRecord::Migration
  def self.up
    add_column :scarichi, :prodotto_id, :integer
    remove_column :scarichi, :carico_id

    execute "CREATE INDEX S_PRODOTTO_FK_IDX ON scarichi (prodotto_id)"
  end

  def self.down
    remove_column :scarichi, :prodotto_id
    add_column :scarichi, :carico_id, :integer
  end
end
