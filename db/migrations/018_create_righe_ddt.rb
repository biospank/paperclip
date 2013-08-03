class CreateRigheDdt < ActiveRecord::Migration
  def self.up
    create_table :righe_ddt do |t|
      t.integer :ddt_id, :null => false
      t.string  :descrizione, :null => false, :limit => 100
      t.integer :qta, :null => false
    end

    execute "CREATE INDEX RIGHE_DDT_IDX ON RIGHE_DDT (id, ddt_id)"

  end

  def self.down
    drop_table :righe_ddt
  end
end
