class AddDataResiduo < ActiveRecord::Migration
  def self.up
    add_column :prima_nota, :data_residuo, :date, :null => true
    execute "CREATE INDEX PRIMA_NOTA_DATA_RESIDUO_IDX ON PRIMA_NOTA (data_residuo)"
  end

  def self.down

  end
end
