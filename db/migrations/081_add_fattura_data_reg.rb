class AddFatturaDataReg < ActiveRecord::Migration
  def self.up
    add_column :fatture_fornitori, :data_registrazione, :date

    execute "CREATE INDEX FATTURE_FORNITORI_DATA_REG_IDX ON fatture_fornitori (data_registrazione)"

  end

  def self.down
    remove_column :fatture_fornitori, :data_registrazione
  end
end
